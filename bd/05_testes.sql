-- =====================================================================
--  Sistema de Gestão de Festivais — MODSI 2026/2027
--  05_testes.sql : testes das restrições da base de dados (SÓ LOCAL)
--
--  ATENÇÃO: altera os dados. Executar sobre uma base acabada de criar
--  (01 -> 02 -> 03) e voltar a criá-la depois, antes do dump final.
--  Cria dois procedimentos auxiliares, que apaga no fim.
--
--  Testa o que a BASE DE DADOS garante (chaves, UNIQUE, CHECK, vistas) e
--  a coerência dos dados de exemplo. As regras garantidas pelo PHP
--  (lotação, prazos, Staff associado, etc.) testam-se na aplicação.
--  Os testes CHECK falham em MySQL < 8.0.16, que ignora essas restrições.
-- =====================================================================
SET NAMES utf8mb4 COLLATE utf8mb4_unicode_ci;   -- igual à collation das tabelas

DROP TEMPORARY TABLE IF EXISTS resultado_testes;
CREATE TEMPORARY TABLE resultado_testes (
  n         INT AUTO_INCREMENT PRIMARY KEY,
  teste     VARCHAR(120),
  esperado  VARCHAR(255),
  obtido    TEXT,
  ok        BOOLEAN
);

DELIMITER //

-- Executa p_sql; p_esperado = parte da mensagem de erro esperada,
-- ou NULL se a instrução deve ter sucesso.
DROP PROCEDURE IF EXISTS t_sql//
CREATE PROCEDURE t_sql(IN p_teste VARCHAR(120), IN p_sql TEXT, IN p_esperado VARCHAR(255))
BEGIN
  DECLARE v_msg TEXT DEFAULT NULL;
  -- SQLWARNING também: em modo estrito, valores inválidos (ex.: ENUM)
  -- são erros mas com SQLSTATE da classe 01.
  DECLARE CONTINUE HANDLER FOR SQLEXCEPTION, SQLWARNING
    GET DIAGNOSTICS CONDITION 1 v_msg = MESSAGE_TEXT;

  SET @t_sql = p_sql;
  PREPARE t_stmt FROM @t_sql;
  EXECUTE t_stmt;
  DEALLOCATE PREPARE t_stmt;

  INSERT INTO resultado_testes (teste, esperado, obtido, ok)
  VALUES (p_teste,
          COALESCE(p_esperado, '(sucesso)'),
          COALESCE(v_msg, '(sucesso)'),
          (p_esperado IS NULL AND v_msg IS NULL)
          OR (p_esperado IS NOT NULL AND v_msg LIKE CONCAT('%', p_esperado, '%')));
END//

-- Compara um valor obtido com o esperado
DROP PROCEDURE IF EXISTS t_valor//
CREATE PROCEDURE t_valor(IN p_teste VARCHAR(120), IN p_obtido VARCHAR(255), IN p_esperado VARCHAR(255))
BEGIN
  INSERT INTO resultado_testes (teste, esperado, obtido, ok)
  VALUES (p_teste, COALESCE(p_esperado, 'NULL'), COALESCE(p_obtido, 'NULL'),
          p_obtido <=> p_esperado);
END//

DELIMITER ;

SET @hoje = CURDATE();

-- =====================================================================
--  1. Coerência dos dados de exemplo (as regras que o PHP vai garantir)
-- =====================================================================
CALL t_valor('Dados: confirmada sem bilhete',
  (SELECT COUNT(*) FROM inscricao i WHERE i.estado = 'confirmada'
      AND NOT EXISTS (SELECT 1 FROM bilhete b WHERE b.id_inscricao = i.id_inscricao)), '0');
CALL t_valor('Dados: confirmada sem pagamento aprovado',
  (SELECT COUNT(*) FROM inscricao i WHERE i.estado = 'confirmada'
      AND NOT EXISTS (SELECT 1 FROM pagamento p WHERE p.inscricao_aprovada = i.id_inscricao)), '0');
CALL t_valor('Dados: cancelada com bilhete não revogado',
  (SELECT COUNT(*) FROM inscricao i JOIN bilhete b ON b.id_inscricao = i.id_inscricao
    WHERE i.estado = 'cancelada' AND b.revogado_em IS NULL), '0');
CALL t_valor('Dados: lotação ultrapassada (RN05)',
  (SELECT COUNT(*) FROM vw_ocupacao_festival WHERE confirmadas > capacidade), '0');
CALL t_valor('Dados: entrada com bilhete inválido (RN11)',
  (SELECT COUNT(*) FROM entrada e JOIN bilhete b ON b.id_bilhete = e.id_bilhete
     JOIN inscricao i ON i.id_inscricao = b.id_inscricao
    WHERE b.revogado_em IS NOT NULL OR i.estado <> 'confirmada'), '0');
CALL t_valor('Dados: entrada fora das datas (RN11)',
  (SELECT COUNT(*) FROM entrada e JOIN bilhete b ON b.id_bilhete = e.id_bilhete
     JOIN inscricao i ON i.id_inscricao = b.id_inscricao
     JOIN festival f ON f.id_festival = i.id_festival
    WHERE DATE(e.validada_em) NOT BETWEEN f.data_inicio AND f.data_fim), '0');
CALL t_valor('Dados: entrada por Staff não associado (RN12)',
  (SELECT COUNT(*) FROM entrada e JOIN bilhete b ON b.id_bilhete = e.id_bilhete
     JOIN inscricao i ON i.id_inscricao = b.id_inscricao
    WHERE NOT EXISTS (SELECT 1 FROM festival_staff fs
                       WHERE fs.id_festival = i.id_festival AND fs.id_utilizador = e.id_staff)), '0');
CALL t_valor('Dados: Staff sem perfil STAFF (RN12)',
  (SELECT COUNT(*) FROM festival_staff fs JOIN utilizador u ON u.id_utilizador = fs.id_utilizador
    WHERE u.perfil_codigo <> 'STAFF'), '0');
CALL t_valor('Dados: organizador sem perfil (RN04)',
  (SELECT COUNT(*) FROM festival f JOIN utilizador u ON u.id_utilizador = f.id_organizador
    WHERE u.perfil_codigo <> 'ORGANIZADOR'), '0');
CALL t_valor('Dados: atuações sobrepostas (RN13)',
  (SELECT COUNT(*) FROM atuacao a JOIN atuacao b
      ON b.id_palco = a.id_palco AND b.id_atuacao > a.id_atuacao
     AND b.inicio < a.fim AND b.fim > a.inicio), '0');
CALL t_valor('Dados: atuação fora das datas (RN13)',
  (SELECT COUNT(*) FROM atuacao a JOIN festival f ON f.id_festival = a.id_festival
    WHERE DATE(a.inicio) NOT BETWEEN f.data_inicio AND f.data_fim), '0');
CALL t_valor('Dados: valor diferente do preço (RN07)',
  (SELECT COUNT(*) FROM inscricao i JOIN festival f ON f.id_festival = i.id_festival
    WHERE i.valor <> f.preco), '0');

-- =====================================================================
--  2. Restrições da base de dados
-- =====================================================================

-- Inscrições (RN06)
CALL t_sql('RN06 inscrição duplicada',
  'INSERT INTO inscricao (id_participante, id_festival, valor) VALUES (7, 2, 49.90)',
  'uk_inscricao_ativa');
CALL t_sql('RN06 nova inscrição após cancelar',
  'INSERT INTO inscricao (id_participante, id_festival, valor) VALUES (11, 1, 35.00)', NULL);
CALL t_valor('RN06 a cancelada mantém-se no histórico',
  (SELECT COUNT(*) FROM inscricao WHERE id_participante = 11 AND id_festival = 1), '2');
CALL t_sql('RN06 duas ativas após cancelar',
  'INSERT INTO inscricao (id_participante, id_festival, valor) VALUES (11, 1, 35.00)',
  'uk_inscricao_ativa');
CALL t_sql('Valor negativo',
  'INSERT INTO inscricao (id_participante, id_festival, valor) VALUES (9, 6, -1)',
  'ck_inscricao_valor');

-- Pagamentos e bilhetes (RN08, RN09)
CALL t_sql('RN08 nova tentativa recusada é aceite',
  'INSERT INTO pagamento (id_inscricao, metodo, resultado, valor) VALUES (1, ''cartao'', ''recusado'', 35)', NULL);
CALL t_sql('RN08 segundo pagamento aprovado',
  'INSERT INTO pagamento (id_inscricao, metodo, resultado, valor) VALUES (1, ''cartao'', ''aprovado'', 35)',
  'uk_pagamento_aprovado');
CALL t_sql('Método de pagamento inválido',
  'INSERT INTO pagamento (id_inscricao, metodo, resultado, valor) VALUES (9, ''paypal'', ''recusado'', 49.90)',
  'metodo');
CALL t_sql('RN09 segundo bilhete na mesma inscrição',
  'INSERT INTO bilhete (id_inscricao, codigo_qr) VALUES (1, REPEAT(''a'', 64))',
  'uk_bilhete_inscricao');
CALL t_sql('RN09 código QR repetido',
  'UPDATE bilhete SET codigo_qr = (SELECT c FROM (SELECT codigo_qr AS c FROM bilhete WHERE id_bilhete = 1) t) WHERE id_bilhete = 2',
  'uk_bilhete_codigo');

-- Entradas (RN11)
CALL t_sql('RN11 segunda entrada com o mesmo bilhete',
  'INSERT INTO entrada (id_bilhete, id_staff) VALUES (1, 4)', 'uk_entrada_bilhete');
CALL t_sql('Entrada com bilhete inexistente',
  'INSERT INTO entrada (id_bilhete, id_staff) VALUES (999, 4)', 'fk_entrada_bilhete');

-- Programação (RN13, RN14)
CALL t_sql('RN13 palco de outro festival',
  'INSERT INTO atuacao (id_festival, id_palco, id_artista, inicio, fim) VALUES (1, 3, 1, TIMESTAMP(@hoje, ''10:00:00''), TIMESTAMP(@hoje, ''11:00:00''))',
  'fk_atuacao_palco');
CALL t_sql('RN13 artista não associado ao festival',
  'INSERT INTO atuacao (id_festival, id_palco, id_artista, inicio, fim) VALUES (1, 1, 5, TIMESTAMP(@hoje, ''10:00:00''), TIMESTAMP(@hoje, ''11:00:00''))',
  'fk_atuacao_festival_artista');
CALL t_sql('RN13 fim antes do início',
  'INSERT INTO atuacao (id_festival, id_palco, id_artista, inicio, fim) VALUES (1, 2, 2, TIMESTAMP(@hoje, ''12:00:00''), TIMESTAMP(@hoje, ''11:00:00''))',
  'ck_atuacao_horario');
CALL t_sql('RN13 atuação válida',
  'INSERT INTO atuacao (id_festival, id_palco, id_artista, inicio, fim) VALUES (1, 2, 2, TIMESTAMP(@hoje, ''12:00:00''), TIMESTAMP(@hoje, ''13:00:00''))',
  NULL);
-- consulta de sobreposição que o PHP usa (04_consultas.sql, UC19)
CALL t_valor('RN13 consulta deteta sobreposição',
  (SELECT COUNT(*) FROM atuacao WHERE id_palco = 1 AND id_atuacao <> 0
      AND inicio < TIMESTAMP(@hoje, '22:00:00') AND fim > TIMESTAMP(@hoje, '21:30:00')), '1');
CALL t_valor('RN13 consulta aceita horário livre',
  (SELECT COUNT(*) FROM atuacao WHERE id_palco = 1 AND id_atuacao <> 0
      AND inicio < TIMESTAMP(@hoje, '16:00:00') AND fim > TIMESTAMP(@hoje, '15:00:00')), '0');
CALL t_sql('Nome de palco repetido no festival',
  'INSERT INTO palco (id_festival, nome) VALUES (1, ''Palco Rio'')', 'uk_palco_nome');
CALL t_sql('RN14 remover palco com atuações',
  'DELETE FROM palco WHERE id_palco = 1', 'fk_atuacao_palco');
CALL t_sql('RN14 desassociar artista com atuações',
  'DELETE FROM festival_artista WHERE id_festival = 1 AND id_artista = 1', 'fk_atuacao_festival_artista');

-- Festivais e contas
CALL t_sql('CHECK datas do festival',
  'INSERT INTO festival (id_organizador, nome, localizacao, data_inicio, data_fim, inscricoes_abrem, inscricoes_fecham, cancelamento_ate, capacidade, preco) VALUES (2, ''X'', ''Porto'', CURDATE(), CURDATE() - INTERVAL 1 DAY, NOW(), NOW() + INTERVAL 1 DAY, NOW(), 10, 5)',
  'ck_festival_datas');
CALL t_sql('CHECK período de inscrições',
  'INSERT INTO festival (id_organizador, nome, localizacao, data_inicio, data_fim, inscricoes_abrem, inscricoes_fecham, cancelamento_ate, capacidade, preco) VALUES (2, ''X'', ''Porto'', CURDATE(), CURDATE(), NOW(), NOW() - INTERVAL 1 DAY, NOW(), 10, 5)',
  'ck_festival_inscricoes');
CALL t_sql('CHECK capacidade positiva',
  'INSERT INTO festival (id_organizador, nome, localizacao, data_inicio, data_fim, inscricoes_abrem, inscricoes_fecham, cancelamento_ate, capacidade, preco) VALUES (2, ''X'', ''Porto'', CURDATE(), CURDATE(), NOW(), NOW() + INTERVAL 1 DAY, NOW(), 0, 5)',
  'ck_festival_capacidade');
CALL t_sql('CHECK preço não negativo',
  'INSERT INTO festival (id_organizador, nome, localizacao, data_inicio, data_fim, inscricoes_abrem, inscricoes_fecham, cancelamento_ate, capacidade, preco) VALUES (2, ''X'', ''Porto'', CURDATE(), CURDATE(), NOW(), NOW() + INTERVAL 1 DAY, NOW(), 10, -5)',
  'ck_festival_preco');
CALL t_sql('Festival válido (fica em rascunho)',
  'INSERT INTO festival (id_organizador, nome, localizacao, data_inicio, data_fim, inscricoes_abrem, inscricoes_fecham, cancelamento_ate, capacidade, preco) VALUES (2, ''Teste'', ''Porto'', CURDATE(), CURDATE(), NOW(), NOW() + INTERVAL 1 DAY, NOW(), 10, 5)',
  NULL);
CALL t_valor('Festival novo fica em rascunho',
  (SELECT estado FROM festival WHERE nome = 'Teste'), 'rascunho');
CALL t_sql('RN01 email duplicado',
  'INSERT INTO utilizador (nome, email, password_hash) VALUES (''X'', ''admin@festivais.pt'', ''x'')',
  'uk_utilizador_email');
CALL t_sql('Idioma inválido',
  'INSERT INTO utilizador (nome, email, password_hash, idioma) VALUES (''X'', ''x@x.pt'', ''x'', ''fr'')',
  'ck_utilizador_idioma');
CALL t_sql('Perfil inexistente',
  'INSERT INTO utilizador (nome, email, password_hash, perfil_codigo) VALUES (''X'', ''y@x.pt'', ''x'', ''VIP'')',
  'fk_utilizador_perfil');
CALL t_sql('RN01 registo sem perfil',
  'INSERT INTO utilizador (nome, email, password_hash) VALUES (''Novo'', ''novo@x.pt'', ''x'')', NULL);
CALL t_valor('RN01 registo fica Participante',
  (SELECT perfil_codigo FROM utilizador WHERE email = 'novo@x.pt'), 'PARTICIPANTE');

-- =====================================================================
--  3. Vistas
-- =====================================================================
CALL t_valor('RN03 rascunho e desativado não são públicos',
  (SELECT COUNT(*) FROM vw_festivais_publicos WHERE id_festival IN (3, 5)), '0');
CALL t_valor('RN03 só publicados e ativos (1, 2, 6)', (SELECT COUNT(*) FROM vw_festivais_publicos), '3');
CALL t_valor('Festival esgotado sem lugares',
  (SELECT lugares_disponiveis FROM vw_festivais_publicos WHERE id_festival = 6), '0');
CALL t_valor('Festival esgotado fechado',
  (SELECT inscricoes_abertas FROM vw_festivais_publicos WHERE id_festival = 6), '0');
CALL t_valor('Atlântico Fest aberto',
  (SELECT inscricoes_abertas FROM vw_festivais_publicos WHERE id_festival = 2), '1');
CALL t_valor('Ocupação: entradas no Sons do Douro',
  (SELECT entradas FROM vw_ocupacao_festival WHERE id_festival = 1), '3');
CALL t_valor('Inscrições: pode cancelar dentro do prazo',
  (SELECT pode_cancelar FROM vw_inscricoes_detalhe WHERE id_inscricao = 7), '1');
CALL t_valor('Inscrições: não pode cancelar fora do prazo',
  (SELECT pode_cancelar FROM vw_inscricoes_detalhe WHERE id_inscricao = 4), '0');
CALL t_valor('Programação: atuações do Atlântico Fest',
  (SELECT COUNT(*) FROM vw_programacao WHERE id_festival = 2), '4');
CALL t_valor('Indicadores: pagamentos recusados',
  (SELECT pagamentos_recusados FROM vw_indicadores_globais), '3');

-- =====================================================================
--  Resultado
-- =====================================================================
SELECT n, IF(ok, 'OK', 'FALHA') AS estado, teste, esperado, obtido
  FROM resultado_testes ORDER BY n;

SELECT SUM(ok) AS ok, SUM(NOT ok) AS falhas, COUNT(*) AS total FROM resultado_testes;

DROP PROCEDURE IF EXISTS t_sql;
DROP PROCEDURE IF EXISTS t_valor;
