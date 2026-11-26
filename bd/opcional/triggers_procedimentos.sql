-- =====================================================================
--  OPCIONAL — triggers e procedimentos
--  NÃO fazem parte da versão mínima. A aplicação PHP garante estas regras.
--  Usar só se o servidor final permitir CREATE TRIGGER / CREATE PROCEDURE
--  e se o grupo decidir passar a lógica para a base de dados.
--  Executar depois de 01_esquema.sql e 02_vistas.sql.
-- =====================================================================

-- =====================================================================
--  TRIGGERS — regras que não se exprimem só com chaves e CHECK
--  Os erros usam SQLSTATE '45000' e um código em MESSAGE_TEXT, que a
--  aplicação traduz para PT/EN.
-- =====================================================================
DELIMITER //

-- RN13: atuação dentro das datas do festival e sem sobreposição no palco
CREATE TRIGGER trg_atuacao_bi BEFORE INSERT ON atuacao
FOR EACH ROW
BEGIN
  IF NOT EXISTS (SELECT 1 FROM festival f
                  WHERE f.id_festival = NEW.id_festival
                    AND DATE(NEW.inicio) BETWEEN f.data_inicio AND f.data_fim) THEN
    SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'ATUACAO_FORA_DATAS';
  END IF;
  IF EXISTS (SELECT 1 FROM atuacao a
              WHERE a.id_palco = NEW.id_palco
                AND a.inicio < NEW.fim AND a.fim > NEW.inicio) THEN
    SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'ATUACAO_SOBREPOSTA';
  END IF;
END//

CREATE TRIGGER trg_atuacao_bu BEFORE UPDATE ON atuacao
FOR EACH ROW
BEGIN
  IF NOT EXISTS (SELECT 1 FROM festival f
                  WHERE f.id_festival = NEW.id_festival
                    AND DATE(NEW.inicio) BETWEEN f.data_inicio AND f.data_fim) THEN
    SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'ATUACAO_FORA_DATAS';
  END IF;
  IF EXISTS (SELECT 1 FROM atuacao a
              WHERE a.id_palco = NEW.id_palco
                AND a.id_atuacao <> NEW.id_atuacao
                AND a.inicio < NEW.fim AND a.fim > NEW.inicio) THEN
    SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'ATUACAO_SOBREPOSTA';
  END IF;
END//

-- RN11, RN12: só entra um bilhete válido, validado por Staff associado
CREATE TRIGGER trg_entrada_bi BEFORE INSERT ON entrada
FOR EACH ROW
BEGIN
  DECLARE v_festival   BIGINT UNSIGNED;
  DECLARE v_estado     VARCHAR(15);
  DECLARE v_revogado   DATETIME;
  DECLARE v_inicio     DATE;
  DECLARE v_fim        DATE;

  SELECT i.id_festival, i.estado, b.revogado_em, f.data_inicio, f.data_fim
    INTO v_festival, v_estado, v_revogado, v_inicio, v_fim
    FROM bilhete b
    JOIN inscricao i ON i.id_inscricao = b.id_inscricao
    JOIN festival  f ON f.id_festival  = i.id_festival
   WHERE b.id_bilhete = NEW.id_bilhete;

  IF v_revogado IS NOT NULL OR v_estado <> 'confirmada' THEN
    SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'BILHETE_INVALIDO';
  END IF;
  IF DATE(NEW.validada_em) NOT BETWEEN v_inicio AND v_fim THEN
    SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'FESTIVAL_NAO_DECORRE';
  END IF;
  IF NOT EXISTS (SELECT 1 FROM festival_staff fs
                   JOIN utilizador u ON u.id_utilizador = fs.id_utilizador
                  WHERE fs.id_festival = v_festival
                    AND fs.id_utilizador = NEW.id_staff
                    AND fs.ativo = TRUE
                    AND u.perfil_codigo = 'STAFF'
                    AND u.ativo = TRUE) THEN
    SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'STAFF_NAO_ASSOCIADO';
  END IF;
END//

-- RN12: só utilizadores com perfil STAFF podem ser associados a festivais
CREATE TRIGGER trg_festival_staff_bi BEFORE INSERT ON festival_staff
FOR EACH ROW
BEGIN
  IF NOT EXISTS (SELECT 1 FROM utilizador
                  WHERE id_utilizador = NEW.id_utilizador
                    AND perfil_codigo = 'STAFF') THEN
    SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'UTILIZADOR_NAO_STAFF';
  END IF;
END//

-- RN04/RN01: o responsável por um festival tem perfil ORGANIZADOR
CREATE TRIGGER trg_festival_bi BEFORE INSERT ON festival
FOR EACH ROW
BEGIN
  IF NOT EXISTS (SELECT 1 FROM utilizador
                  WHERE id_utilizador = NEW.id_organizador
                    AND perfil_codigo = 'ORGANIZADOR') THEN
    SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'UTILIZADOR_NAO_ORGANIZADOR';
  END IF;
END//

DELIMITER ;

-- =====================================================================
--  PROCEDIMENTOS (transações)
--  Erros de negócio: SQLSTATE '45000' com um código em MESSAGE_TEXT.
--  Ordem de bloqueio comum: festival -> inscricao (evita deadlocks).
-- =====================================================================
DELIMITER //

-- ---------------------------------------------------------------------
-- UC10 — Inscrever-se num festival (RN05, RN06, RN07)
-- ---------------------------------------------------------------------
DROP PROCEDURE IF EXISTS sp_inscrever//
CREATE PROCEDURE sp_inscrever(
  IN  p_participante BIGINT UNSIGNED,
  IN  p_festival     BIGINT UNSIGNED,
  OUT p_id_inscricao BIGINT UNSIGNED)
BEGIN
  DECLARE v_perfil      VARCHAR(20);
  DECLARE v_estado      VARCHAR(15);
  DECLARE v_ativo       BOOLEAN;
  DECLARE v_abrem       DATETIME;
  DECLARE v_fecham      DATETIME;
  DECLARE v_capacidade  INT UNSIGNED;
  DECLARE v_preco       DECIMAL(10,2);
  DECLARE v_confirmadas INT DEFAULT 0;

  DECLARE EXIT HANDLER FOR SQLEXCEPTION
  BEGIN
    ROLLBACK;
    RESIGNAL;
  END;

  SET p_id_inscricao = NULL;
  START TRANSACTION;

  SELECT perfil_codigo INTO v_perfil
    FROM utilizador
   WHERE id_utilizador = p_participante AND ativo = TRUE;
  IF v_perfil IS NULL OR v_perfil <> 'PARTICIPANTE' THEN
    SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'SEM_PERMISSAO';
  END IF;

  -- bloqueia o festival: serializa inscrições/pagamentos do mesmo festival
  SELECT estado, ativo, inscricoes_abrem, inscricoes_fecham, capacidade, preco
    INTO v_estado, v_ativo, v_abrem, v_fecham, v_capacidade, v_preco
    FROM festival
   WHERE id_festival = p_festival
     FOR UPDATE;
  IF v_estado IS NULL THEN
    SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'FESTIVAL_INEXISTENTE';
  END IF;
  IF v_estado <> 'publicado' OR NOT v_ativo
     OR NOW() NOT BETWEEN v_abrem AND v_fecham THEN
    SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'INSCRICOES_FECHADAS';
  END IF;

  SELECT COUNT(*) INTO v_confirmadas
    FROM inscricao
   WHERE id_festival = p_festival AND estado = 'confirmada';
  IF v_confirmadas >= v_capacidade THEN
    SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'LOTACAO_ESGOTADA';
  END IF;

  IF EXISTS (SELECT 1 FROM inscricao
              WHERE id_participante = p_participante
                AND id_festival = p_festival
                AND estado <> 'cancelada') THEN
    SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'INSCRICAO_DUPLICADA';
  END IF;

  INSERT INTO inscricao (id_participante, id_festival, valor)
  VALUES (p_participante, p_festival, v_preco);
  SET p_id_inscricao = LAST_INSERT_ID();

  COMMIT;
END//

-- ---------------------------------------------------------------------
-- UC11 — Efetuar pagamento simulado (RN08, RN09)
--   p_resultado : 'aprovado' ou 'recusado' (decidido pela simulação na app)
--   p_codigo_qr : bin2hex(random_bytes(32)) gerado em PHP; se NULL, é
--                 gerado aqui (apenas para testes e dados de exemplo).
-- ---------------------------------------------------------------------
DROP PROCEDURE IF EXISTS sp_pagar//
CREATE PROCEDURE sp_pagar(
  IN  p_inscricao    BIGINT UNSIGNED,
  IN  p_participante BIGINT UNSIGNED,
  IN  p_metodo       VARCHAR(10),
  IN  p_resultado    VARCHAR(10),
  IN  p_codigo_qr    CHAR(64),
  OUT p_id_bilhete   BIGINT UNSIGNED)
BEGIN
  DECLARE v_festival    BIGINT UNSIGNED;
  DECLARE v_dono        BIGINT UNSIGNED;
  DECLARE v_estado      VARCHAR(15);
  DECLARE v_valor       DECIMAL(10,2);
  DECLARE v_capacidade  INT UNSIGNED;
  DECLARE v_confirmadas INT DEFAULT 0;

  DECLARE EXIT HANDLER FOR SQLEXCEPTION
  BEGIN
    ROLLBACK;
    RESIGNAL;
  END;

  SET p_id_bilhete = NULL;

  SELECT id_festival INTO v_festival
    FROM inscricao WHERE id_inscricao = p_inscricao;
  IF v_festival IS NULL THEN
    SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'INSCRICAO_INEXISTENTE';
  END IF;

  START TRANSACTION;

  SELECT capacidade INTO v_capacidade
    FROM festival WHERE id_festival = v_festival
     FOR UPDATE;

  SELECT id_participante, estado, valor
    INTO v_dono, v_estado, v_valor
    FROM inscricao WHERE id_inscricao = p_inscricao
     FOR UPDATE;

  IF v_dono <> p_participante THEN
    SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'INSCRICAO_INEXISTENTE';
  END IF;
  IF v_estado <> 'pendente' THEN
    SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'INSCRICAO_NAO_PENDENTE';
  END IF;

  IF p_resultado = 'aprovado' THEN
    SELECT COUNT(*) INTO v_confirmadas
      FROM inscricao
     WHERE id_festival = v_festival AND estado = 'confirmada';
    IF v_confirmadas >= v_capacidade THEN
      SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'LOTACAO_ESGOTADA';
    END IF;
  END IF;

  INSERT INTO pagamento (id_inscricao, metodo, resultado, valor)
  VALUES (p_inscricao, p_metodo, p_resultado, v_valor);

  IF p_resultado = 'aprovado' THEN
    UPDATE inscricao
       SET estado = 'confirmada', confirmada_em = NOW()
     WHERE id_inscricao = p_inscricao;

    INSERT INTO bilhete (id_inscricao, codigo_qr)
    VALUES (p_inscricao,
            COALESCE(p_codigo_qr, SHA2(CONCAT(UUID(), RAND()), 256)));
    SET p_id_bilhete = LAST_INSERT_ID();
  END IF;

  COMMIT;
END//

-- ---------------------------------------------------------------------
-- UC14 — Cancelar inscrição (RN10)
-- ---------------------------------------------------------------------
DROP PROCEDURE IF EXISTS sp_cancelar_inscricao//
CREATE PROCEDURE sp_cancelar_inscricao(
  IN p_inscricao    BIGINT UNSIGNED,
  IN p_participante BIGINT UNSIGNED)
BEGIN
  DECLARE v_festival   BIGINT UNSIGNED;
  DECLARE v_dono       BIGINT UNSIGNED;
  DECLARE v_estado     VARCHAR(15);
  DECLARE v_limite     DATETIME;

  DECLARE EXIT HANDLER FOR SQLEXCEPTION
  BEGIN
    ROLLBACK;
    RESIGNAL;
  END;

  SELECT id_festival INTO v_festival
    FROM inscricao WHERE id_inscricao = p_inscricao;
  IF v_festival IS NULL THEN
    SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'INSCRICAO_INEXISTENTE';
  END IF;

  START TRANSACTION;

  SELECT cancelamento_ate INTO v_limite
    FROM festival WHERE id_festival = v_festival
     FOR UPDATE;

  SELECT id_participante, estado INTO v_dono, v_estado
    FROM inscricao WHERE id_inscricao = p_inscricao
     FOR UPDATE;

  IF v_dono <> p_participante THEN
    SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'INSCRICAO_INEXISTENTE';
  END IF;
  IF v_estado = 'cancelada' THEN
    SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'INSCRICAO_JA_CANCELADA';
  END IF;
  IF NOW() > v_limite THEN
    SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'PRAZO_CANCELAMENTO_ULTRAPASSADO';
  END IF;
  IF EXISTS (SELECT 1 FROM entrada e
               JOIN bilhete b ON b.id_bilhete = e.id_bilhete
              WHERE b.id_inscricao = p_inscricao) THEN
    SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'ENTRADA_JA_REGISTADA';
  END IF;

  UPDATE inscricao
     SET estado = 'cancelada', cancelada_em = NOW()
   WHERE id_inscricao = p_inscricao;

  UPDATE bilhete
     SET revogado_em = NOW()
   WHERE id_inscricao = p_inscricao AND revogado_em IS NULL;

  COMMIT;
END//

-- ---------------------------------------------------------------------
-- UC24 / UC25 — Verificar bilhete e (opcionalmente) registar a entrada
--   p_registar = FALSE : só verifica (UC24)
--   p_registar = TRUE  : verifica e regista a entrada (UC25)
--   p_resultado: VALIDO | ENTRADA_REGISTADA | STAFF_NAO_ASSOCIADO |
--                BILHETE_INEXISTENTE | BILHETE_OUTRO_FESTIVAL |
--                BILHETE_REVOGADO | INSCRICAO_NAO_CONFIRMADA |
--                FESTIVAL_NAO_DECORRE | BILHETE_JA_UTILIZADO
-- ---------------------------------------------------------------------
DROP PROCEDURE IF EXISTS sp_verificar_bilhete//
CREATE PROCEDURE sp_verificar_bilhete(
  IN  p_codigo_qr    CHAR(64),
  IN  p_staff        BIGINT UNSIGNED,
  IN  p_festival     BIGINT UNSIGNED,
  IN  p_registar     BOOLEAN,
  OUT p_resultado    VARCHAR(30),
  OUT p_participante VARCHAR(120),
  OUT p_entrada_em   DATETIME)
proc: BEGIN
  DECLARE v_bilhete   BIGINT UNSIGNED;
  DECLARE v_festival  BIGINT UNSIGNED;
  DECLARE v_estado    VARCHAR(15);
  DECLARE v_revogado  DATETIME;
  DECLARE v_inicio    DATE;
  DECLARE v_fim       DATE;
  DECLARE v_duplicado BOOLEAN DEFAULT FALSE;

  -- leitura simultânea noutro posto: a UNIQUE de entrada rejeita o 2.º registo
  DECLARE CONTINUE HANDLER FOR 1062 SET v_duplicado = TRUE;

  SET p_resultado = NULL, p_participante = NULL, p_entrada_em = NULL;

  IF NOT EXISTS (SELECT 1 FROM festival_staff fs
                   JOIN utilizador u ON u.id_utilizador = fs.id_utilizador
                  WHERE fs.id_festival = p_festival
                    AND fs.id_utilizador = p_staff
                    AND fs.ativo = TRUE
                    AND u.perfil_codigo = 'STAFF'
                    AND u.ativo = TRUE) THEN
    SET p_resultado = 'STAFF_NAO_ASSOCIADO';
    LEAVE proc;
  END IF;

  SELECT b.id_bilhete, i.id_festival, i.estado, b.revogado_em,
         u.nome, e.validada_em, f.data_inicio, f.data_fim
    INTO v_bilhete, v_festival, v_estado, v_revogado,
         p_participante, p_entrada_em, v_inicio, v_fim
    FROM bilhete b
    JOIN inscricao  i ON i.id_inscricao  = b.id_inscricao
    JOIN utilizador u ON u.id_utilizador = i.id_participante
    JOIN festival   f ON f.id_festival   = i.id_festival
    LEFT JOIN entrada e ON e.id_bilhete  = b.id_bilhete
   WHERE b.codigo_qr = p_codigo_qr;

  IF v_bilhete IS NULL THEN
    SET p_resultado = 'BILHETE_INEXISTENTE';
  ELSEIF v_festival <> p_festival THEN
    SET p_resultado = 'BILHETE_OUTRO_FESTIVAL', p_participante = NULL, p_entrada_em = NULL;
  ELSEIF v_revogado IS NOT NULL THEN
    SET p_resultado = 'BILHETE_REVOGADO';
  ELSEIF v_estado <> 'confirmada' THEN
    SET p_resultado = 'INSCRICAO_NAO_CONFIRMADA';
  ELSEIF p_entrada_em IS NOT NULL THEN
    SET p_resultado = 'BILHETE_JA_UTILIZADO';
  ELSEIF CURDATE() NOT BETWEEN v_inicio AND v_fim THEN
    SET p_resultado = 'FESTIVAL_NAO_DECORRE';
  ELSEIF NOT p_registar THEN
    SET p_resultado = 'VALIDO';
  ELSE
    INSERT INTO entrada (id_bilhete, id_staff) VALUES (v_bilhete, p_staff);
    IF v_duplicado THEN
      SET p_resultado = 'BILHETE_JA_UTILIZADO';
      SELECT validada_em INTO p_entrada_em FROM entrada WHERE id_bilhete = v_bilhete;
    ELSE
      SET p_resultado = 'ENTRADA_REGISTADA', p_entrada_em = NOW();
    END IF;
  END IF;
END//

DELIMITER ;
