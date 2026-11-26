-- =====================================================================
--  Sistema de Gestão de Festivais — IMPORTAÇÃO NO SERVIDOR DO ISEP
--  phpmyadmin.dee.isep.ipp.pt (MariaDB 10.11) — base de dados: 1211154
--
--  Como usar: phpMyAdmin → separador "Importar" → escolher este ficheiro
--  → "Importar". A linha USE abaixo escolhe a base de dados do grupo.
--  Junta 01_esquema.sql + 02_vistas.sql + 03_dados_exemplo.sql.
--  ATENÇÃO: apaga e recria as tabelas da aplicação (os dados voltam ao
--  estado inicial). Ficheiro gerado por gerar.sh — alterar os 01–03.
-- =====================================================================

USE `1211154`;

-- >>>>>>>>>>>>>>>> 01_esquema.sql <<<<<<<<<<<<<<<<
-- =====================================================================
--  Sistema de Gestão de Festivais — MODSI 2026/2027
--  01_esquema.sql : tabelas e restrições
--
--  Versão "mínima": só tabelas, chaves, UNIQUE, CHECK e colunas geradas,
--  para funcionar mesmo num alojamento limitado (sem triggers nem
--  procedimentos). As regras que não cabem aqui são garantidas pela
--  aplicação PHP (ver LEIAME.md).
--  Executar DENTRO da base de dados escolhida (no phpMyAdmin: selecionar
--  a base e importar). Compatível com MySQL 5.7+ e MariaDB 10.2+;
--  as restrições CHECK só são aplicadas a partir de MySQL 8.0.16 / MariaDB 10.2.
--  As referências RNxx correspondem às regras de negócio do relatório.
-- =====================================================================
SET NAMES utf8mb4 COLLATE utf8mb4_unicode_ci;   -- igual à collation das tabelas

SET FOREIGN_KEY_CHECKS = 0;
DROP TABLE IF EXISTS entrada, bilhete, pagamento, inscricao, atuacao, palco,
                     festival_artista, artista, festival_staff, festival,
                     utilizador, perfil;
SET FOREIGN_KEY_CHECKS = 1;

-- ---------------------------------------------------------------------
-- perfil: tipos de conta (RN01)
-- ---------------------------------------------------------------------
CREATE TABLE perfil (
  codigo     VARCHAR(20)  NOT NULL,
  descricao  VARCHAR(100) NOT NULL,
  PRIMARY KEY (codigo)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- ---------------------------------------------------------------------
-- utilizador
-- ---------------------------------------------------------------------
CREATE TABLE utilizador (
  id_utilizador  BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,
  nome           VARCHAR(120)    NOT NULL,
  email          VARCHAR(254)    NOT NULL,
  password_hash  VARCHAR(255)    NOT NULL,
  perfil_codigo  VARCHAR(20)     NOT NULL DEFAULT 'PARTICIPANTE',
  idioma         CHAR(2)         NOT NULL DEFAULT 'pt',
  ativo          BOOLEAN         NOT NULL DEFAULT TRUE,
  criado_em      DATETIME        NOT NULL DEFAULT CURRENT_TIMESTAMP,
  PRIMARY KEY (id_utilizador),
  UNIQUE KEY uk_utilizador_email (email),
  KEY ix_utilizador_perfil (perfil_codigo),
  CONSTRAINT fk_utilizador_perfil FOREIGN KEY (perfil_codigo)
    REFERENCES perfil (codigo) ON UPDATE CASCADE ON DELETE RESTRICT,
  CONSTRAINT ck_utilizador_idioma CHECK (idioma IN ('pt', 'en'))
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- ---------------------------------------------------------------------
-- festival
--   estado : gerido pelo Organizador        (RN03)
--   ativo  : gerido pelo Administrador      (RN03)
--   Os festivais não são apagados: cancelam-se ou terminam.
-- ---------------------------------------------------------------------
CREATE TABLE festival (
  id_festival        BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,
  id_organizador     BIGINT UNSIGNED NOT NULL,
  nome               VARCHAR(160)    NOT NULL,
  descricao          TEXT            NULL,
  localizacao        VARCHAR(200)    NOT NULL,
  data_inicio        DATE            NOT NULL,
  data_fim           DATE            NOT NULL,
  inscricoes_abrem   DATETIME        NOT NULL,
  inscricoes_fecham  DATETIME        NOT NULL,
  cancelamento_ate   DATETIME        NOT NULL,
  capacidade         INT UNSIGNED    NOT NULL,
  preco              DECIMAL(10,2)   NOT NULL DEFAULT 0.00,
  estado             ENUM('rascunho','publicado','cancelado','terminado')
                                     NOT NULL DEFAULT 'rascunho',
  ativo              BOOLEAN         NOT NULL DEFAULT TRUE,
  criado_em          DATETIME        NOT NULL DEFAULT CURRENT_TIMESTAMP,
  PRIMARY KEY (id_festival),
  KEY ix_festival_publico (estado, ativo, data_inicio),
  KEY ix_festival_nome (nome),
  KEY ix_festival_localizacao (localizacao),
  KEY ix_festival_organizador (id_organizador),
  CONSTRAINT fk_festival_organizador FOREIGN KEY (id_organizador)
    REFERENCES utilizador (id_utilizador) ON DELETE RESTRICT,
  CONSTRAINT ck_festival_datas        CHECK (data_fim >= data_inicio),
  CONSTRAINT ck_festival_inscricoes   CHECK (inscricoes_fecham > inscricoes_abrem),
  CONSTRAINT ck_festival_capacidade   CHECK (capacidade > 0),
  CONSTRAINT ck_festival_preco        CHECK (preco >= 0)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- ---------------------------------------------------------------------
-- festival_staff: associação Staff <-> festival (RN12)
--   Remover = ativo FALSE, para manter o histórico das entradas.
-- ---------------------------------------------------------------------
CREATE TABLE festival_staff (
  id_festival    BIGINT UNSIGNED NOT NULL,
  id_utilizador  BIGINT UNSIGNED NOT NULL,
  associado_em   DATETIME        NOT NULL DEFAULT CURRENT_TIMESTAMP,
  ativo          BOOLEAN         NOT NULL DEFAULT TRUE,
  PRIMARY KEY (id_festival, id_utilizador),
  KEY ix_festival_staff_utilizador (id_utilizador),
  CONSTRAINT fk_fstaff_festival FOREIGN KEY (id_festival)
    REFERENCES festival (id_festival) ON DELETE RESTRICT,
  CONSTRAINT fk_fstaff_utilizador FOREIGN KEY (id_utilizador)
    REFERENCES utilizador (id_utilizador) ON DELETE RESTRICT
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- ---------------------------------------------------------------------
-- artista: catálogo partilhado entre organizadores
-- ---------------------------------------------------------------------
CREATE TABLE artista (
  id_artista  BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,
  nome        VARCHAR(160)    NOT NULL,
  genero      VARCHAR(80)     NULL,
  biografia   TEXT            NULL,
  PRIMARY KEY (id_artista),
  KEY ix_artista_nome (nome)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- ---------------------------------------------------------------------
-- festival_artista: artistas associados a cada festival (N:M)
-- ---------------------------------------------------------------------
CREATE TABLE festival_artista (
  id_festival  BIGINT UNSIGNED NOT NULL,
  id_artista   BIGINT UNSIGNED NOT NULL,
  PRIMARY KEY (id_festival, id_artista),
  KEY ix_fartista_artista (id_artista),
  CONSTRAINT fk_fartista_festival FOREIGN KEY (id_festival)
    REFERENCES festival (id_festival) ON DELETE RESTRICT,
  CONSTRAINT fk_fartista_artista FOREIGN KEY (id_artista)
    REFERENCES artista (id_artista) ON DELETE RESTRICT
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- ---------------------------------------------------------------------
-- palco
--   uk_palco_festival existe para suportar a FK composta de atuacao.
-- ---------------------------------------------------------------------
CREATE TABLE palco (
  id_palco     BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,
  id_festival  BIGINT UNSIGNED NOT NULL,
  nome         VARCHAR(100)    NOT NULL,
  PRIMARY KEY (id_palco),
  UNIQUE KEY uk_palco_nome (id_festival, nome),
  UNIQUE KEY uk_palco_festival (id_palco, id_festival),
  CONSTRAINT fk_palco_festival FOREIGN KEY (id_festival)
    REFERENCES festival (id_festival) ON DELETE RESTRICT
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- ---------------------------------------------------------------------
-- atuacao: programação (RN13, RN14)
--   As FKs compostas garantem que artista e palco são do mesmo festival.
--   ON DELETE RESTRICT impede remover palcos/artistas com atuações.
-- ---------------------------------------------------------------------
CREATE TABLE atuacao (
  id_atuacao   BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,
  id_festival  BIGINT UNSIGNED NOT NULL,
  id_palco     BIGINT UNSIGNED NOT NULL,
  id_artista   BIGINT UNSIGNED NOT NULL,
  inicio       DATETIME        NOT NULL,
  fim          DATETIME        NOT NULL,
  PRIMARY KEY (id_atuacao),
  KEY ix_atuacao_palco_inicio (id_palco, inicio),
  KEY ix_atuacao_festival_inicio (id_festival, inicio),
  KEY ix_atuacao_festival_artista (id_festival, id_artista),
  CONSTRAINT fk_atuacao_festival_artista FOREIGN KEY (id_festival, id_artista)
    REFERENCES festival_artista (id_festival, id_artista) ON DELETE RESTRICT,
  CONSTRAINT fk_atuacao_palco FOREIGN KEY (id_palco, id_festival)
    REFERENCES palco (id_palco, id_festival) ON DELETE RESTRICT,
  CONSTRAINT ck_atuacao_horario CHECK (fim > inicio)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- ---------------------------------------------------------------------
-- inscricao (RN05, RN06, RN07)
--   No máximo uma inscrição NÃO cancelada por participante e festival.
--   id_festival_ativa = id_festival enquanto a inscrição não estiver
--   cancelada e NULL depois; como os NULL não colidem no UNIQUE, quem
--   cancela pode voltar a inscrever-se (nova linha) e a inscrição
--   cancelada fica como histórico, com o seu pagamento e bilhete.
-- ---------------------------------------------------------------------
CREATE TABLE inscricao (
  id_inscricao       BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,
  id_participante    BIGINT UNSIGNED NOT NULL,
  id_festival        BIGINT UNSIGNED NOT NULL,
  estado             ENUM('pendente','confirmada','cancelada')
                                     NOT NULL DEFAULT 'pendente',
  valor              DECIMAL(10,2)   NOT NULL,
  criada_em          DATETIME        NOT NULL DEFAULT CURRENT_TIMESTAMP,
  confirmada_em      DATETIME        NULL,
  cancelada_em       DATETIME        NULL,
  id_festival_ativa  BIGINT UNSIGNED
                     GENERATED ALWAYS AS (IF(estado <> 'cancelada', id_festival, NULL)) STORED,
  PRIMARY KEY (id_inscricao),
  UNIQUE KEY uk_inscricao_ativa (id_participante, id_festival_ativa),
  KEY ix_inscricao_festival_estado (id_festival, estado),
  CONSTRAINT fk_inscricao_participante FOREIGN KEY (id_participante)
    REFERENCES utilizador (id_utilizador) ON DELETE RESTRICT,
  CONSTRAINT fk_inscricao_festival FOREIGN KEY (id_festival)
    REFERENCES festival (id_festival) ON DELETE RESTRICT,
  CONSTRAINT ck_inscricao_valor CHECK (valor >= 0)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- ---------------------------------------------------------------------
-- pagamento: todas as tentativas, no máximo uma aprovada (RN08)
--   inscricao_aprovada = id_inscricao se aprovado, senão NULL.
--   Como os NULL não colidem num índice UNIQUE, só pode haver um
--   pagamento aprovado por inscrição.
-- ---------------------------------------------------------------------
CREATE TABLE pagamento (
  id_pagamento        BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,
  id_inscricao        BIGINT UNSIGNED NOT NULL,
  metodo              ENUM('cartao','mbway','multibanco') NOT NULL,
  resultado           ENUM('aprovado','recusado')         NOT NULL,
  valor               DECIMAL(10,2)   NOT NULL,
  criado_em           DATETIME        NOT NULL DEFAULT CURRENT_TIMESTAMP,
  inscricao_aprovada  BIGINT UNSIGNED
                      GENERATED ALWAYS AS (IF(resultado = 'aprovado', id_inscricao, NULL)) STORED,
  PRIMARY KEY (id_pagamento),
  UNIQUE KEY uk_pagamento_aprovado (inscricao_aprovada),
  KEY ix_pagamento_inscricao (id_inscricao),
  KEY ix_pagamento_data (criado_em),
  CONSTRAINT fk_pagamento_inscricao FOREIGN KEY (id_inscricao)
    REFERENCES inscricao (id_inscricao) ON DELETE RESTRICT,
  CONSTRAINT ck_pagamento_valor CHECK (valor >= 0)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- ---------------------------------------------------------------------
-- bilhete: um por inscrição confirmada, código QR único (RN09, RN10)
--   codigo_qr = 32 bytes aleatórios em hexadecimal (gerados em PHP com
--   bin2hex(random_bytes(32))).
-- ---------------------------------------------------------------------
CREATE TABLE bilhete (
  id_bilhete    BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,
  id_inscricao  BIGINT UNSIGNED NOT NULL,
  codigo_qr     CHAR(64)        NOT NULL,
  emitido_em    DATETIME        NOT NULL DEFAULT CURRENT_TIMESTAMP,
  revogado_em   DATETIME        NULL,
  PRIMARY KEY (id_bilhete),
  UNIQUE KEY uk_bilhete_inscricao (id_inscricao),
  UNIQUE KEY uk_bilhete_codigo (codigo_qr),
  CONSTRAINT fk_bilhete_inscricao FOREIGN KEY (id_inscricao)
    REFERENCES inscricao (id_inscricao) ON DELETE RESTRICT
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- ---------------------------------------------------------------------
-- entrada: no máximo uma por bilhete (RN11)
-- ---------------------------------------------------------------------
CREATE TABLE entrada (
  id_entrada   BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,
  id_bilhete   BIGINT UNSIGNED NOT NULL,
  id_staff     BIGINT UNSIGNED NOT NULL,
  validada_em  DATETIME        NOT NULL DEFAULT CURRENT_TIMESTAMP,
  PRIMARY KEY (id_entrada),
  UNIQUE KEY uk_entrada_bilhete (id_bilhete),
  KEY ix_entrada_staff (id_staff),
  KEY ix_entrada_data (validada_em),
  CONSTRAINT fk_entrada_bilhete FOREIGN KEY (id_bilhete)
    REFERENCES bilhete (id_bilhete) ON DELETE RESTRICT,
  CONSTRAINT fk_entrada_staff FOREIGN KEY (id_staff)
    REFERENCES utilizador (id_utilizador) ON DELETE RESTRICT
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- >>>>>>>>>>>>>>>> 02_vistas.sql <<<<<<<<<<<<<<<<
-- =====================================================================
--  Sistema de Gestão de Festivais — MODSI 2026/2027
--  02_vistas.sql : vistas usadas pela aplicação
--  Executar depois de 01_esquema.sql (dentro da base de dados escolhida).
--  Se o servidor não permitir CREATE VIEW, as mesmas consultas passam
--  para os Models do PHP.
-- =====================================================================
SET NAMES utf8mb4 COLLATE utf8mb4_unicode_ci;   -- igual à collation das tabelas

-- =====================================================================
--  VISTAS
-- =====================================================================

-- Festivais visíveis ao público (RN03) — UC01 a UC04
CREATE OR REPLACE VIEW vw_festivais_publicos AS
SELECT f.id_festival,
       f.nome,
       f.descricao,
       f.localizacao,
       f.data_inicio,
       f.data_fim,
       f.preco,
       f.capacidade,
       f.inscricoes_abrem,
       f.inscricoes_fecham,
       f.cancelamento_ate,
       CAST(f.capacidade AS SIGNED) - COALESCE(c.confirmadas, 0) AS lugares_disponiveis,
       (NOW() BETWEEN f.inscricoes_abrem AND f.inscricoes_fecham
        AND f.capacidade > COALESCE(c.confirmadas, 0))           AS inscricoes_abertas,
       u.nome AS organizador
  FROM festival f
  JOIN utilizador u ON u.id_utilizador = f.id_organizador
  LEFT JOIN (SELECT id_festival, COUNT(*) AS confirmadas
               FROM inscricao
              WHERE estado = 'confirmada'
              GROUP BY id_festival) c ON c.id_festival = f.id_festival
 WHERE f.estado = 'publicado'
   AND f.ativo = TRUE;

-- Programação de cada festival — UC05, UC19
CREATE OR REPLACE VIEW vw_programacao AS
SELECT a.id_atuacao,
       a.id_festival,
       DATE(a.inicio) AS dia,
       a.inicio,
       a.fim,
       p.id_palco,
       p.nome         AS palco,
       ar.id_artista,
       ar.nome        AS artista,
       ar.genero
  FROM atuacao a
  JOIN palco   p  ON p.id_palco    = a.id_palco
  JOIN artista ar ON ar.id_artista = a.id_artista;

-- Inscrições com participante, festival, bilhete e entrada — UC12, UC13, UC21, UC23
CREATE OR REPLACE VIEW vw_inscricoes_detalhe AS
SELECT i.id_inscricao,
       i.id_participante,
       u.nome          AS participante,
       u.email,
       i.id_festival,
       f.nome          AS festival,
       f.localizacao,
       f.data_inicio,
       f.data_fim,
       f.cancelamento_ate,
       i.estado,
       i.valor,
       i.criada_em,
       i.confirmada_em,
       i.cancelada_em,
       b.id_bilhete,
       b.codigo_qr,
       b.revogado_em,
       e.validada_em   AS entrada_em,
       (e.id_entrada IS NOT NULL) AS entrou,
       (i.estado <> 'cancelada'
        AND NOW() <= f.cancelamento_ate
        AND e.id_entrada IS NULL)  AS pode_cancelar
  FROM inscricao i
  JOIN utilizador u ON u.id_utilizador = i.id_participante
  JOIN festival   f ON f.id_festival   = i.id_festival
  LEFT JOIN bilhete b ON b.id_inscricao = i.id_inscricao
  LEFT JOIN entrada e ON e.id_bilhete   = b.id_bilhete;

-- Histórico de entradas — UC26
CREATE OR REPLACE VIEW vw_entradas_detalhe AS
SELECT e.id_entrada,
       e.validada_em,
       i.id_festival,
       f.nome  AS festival,
       p.id_utilizador AS id_participante,
       p.nome  AS participante,
       s.id_utilizador AS id_staff,
       s.nome  AS staff
  FROM entrada e
  JOIN bilhete    b ON b.id_bilhete    = e.id_bilhete
  JOIN inscricao  i ON i.id_inscricao  = b.id_inscricao
  JOIN festival   f ON f.id_festival   = i.id_festival
  JOIN utilizador p ON p.id_utilizador = i.id_participante
  JOIN utilizador s ON s.id_utilizador = e.id_staff;

-- Ocupação e receita por festival — UC21, UC29
CREATE OR REPLACE VIEW vw_ocupacao_festival AS
SELECT f.id_festival,
       f.nome,
       f.id_organizador,
       f.estado,
       f.ativo,
       f.data_inicio,
       f.data_fim,
       f.capacidade,
       COUNT(CASE WHEN i.estado = 'pendente'   THEN 1 END) AS pendentes,
       COUNT(CASE WHEN i.estado = 'confirmada' THEN 1 END) AS confirmadas,
       COUNT(CASE WHEN i.estado = 'cancelada'  THEN 1 END) AS canceladas,
       COUNT(e.id_entrada)                                 AS entradas,
       ROUND(100 * COUNT(CASE WHEN i.estado = 'confirmada' THEN 1 END)
             / f.capacidade, 1)                            AS taxa_ocupacao,
       COALESCE(SUM(CASE WHEN i.estado = 'confirmada' THEN i.valor END), 0) AS receita
  FROM festival f
  LEFT JOIN inscricao i ON i.id_festival  = f.id_festival
  LEFT JOIN bilhete   b ON b.id_inscricao = i.id_inscricao
  LEFT JOIN entrada   e ON e.id_bilhete   = b.id_bilhete
 GROUP BY f.id_festival;

-- Indicadores globais (uma linha) — UC31
CREATE OR REPLACE VIEW vw_indicadores_globais AS
SELECT
  (SELECT COUNT(*) FROM utilizador WHERE perfil_codigo = 'PARTICIPANTE') AS participantes,
  (SELECT COUNT(*) FROM utilizador WHERE perfil_codigo = 'ORGANIZADOR')  AS organizadores,
  (SELECT COUNT(*) FROM utilizador WHERE perfil_codigo = 'STAFF')        AS staff,
  (SELECT COUNT(*) FROM utilizador WHERE perfil_codigo = 'ADMIN')        AS administradores,
  (SELECT COUNT(*) FROM festival   WHERE estado = 'publicado')           AS festivais_publicados,
  (SELECT COUNT(*) FROM festival   WHERE estado = 'rascunho')            AS festivais_rascunho,
  (SELECT COUNT(*) FROM festival   WHERE estado = 'terminado')           AS festivais_terminados,
  (SELECT COUNT(*) FROM festival   WHERE estado = 'cancelado')           AS festivais_cancelados,
  (SELECT COUNT(*) FROM inscricao  WHERE estado = 'pendente')            AS inscricoes_pendentes,
  (SELECT COUNT(*) FROM inscricao  WHERE estado = 'confirmada')          AS inscricoes_confirmadas,
  (SELECT COUNT(*) FROM inscricao  WHERE estado = 'cancelada')           AS inscricoes_canceladas,
  (SELECT COUNT(*) FROM pagamento  WHERE resultado = 'aprovado')         AS pagamentos_aprovados,
  (SELECT COUNT(*) FROM pagamento  WHERE resultado = 'recusado')         AS pagamentos_recusados,
  (SELECT COALESCE(SUM(valor), 0) FROM pagamento WHERE resultado = 'aprovado') AS receita_simulada;

-- >>>>>>>>>>>>>>>> 03_dados_exemplo.sql <<<<<<<<<<<<<<<<
-- =====================================================================
--  Sistema de Gestão de Festivais — MODSI 2026/2027
--  03_dados_exemplo.sql : dados para demonstração
--  Executar depois de 02_vistas.sql (dentro da base de dados escolhida)
--
--  As datas são RELATIVAS ao dia em que o script é executado, para que
--  haja sempre: um festival a decorrer hoje (validação de entradas), um
--  festival futuro com inscrições abertas, um esgotado, um terminado,
--  um em rascunho e um desativado pelo Administrador.
--
--  Palavra-passe de TODAS as contas de demonstração:  Demo1234!
-- =====================================================================
SET NAMES utf8mb4 COLLATE utf8mb4_unicode_ci;   -- igual à collation das tabelas
SET @hoje = CURDATE();
SET @hash = '$2y$10$VD52LCoflMO4oZstlpPqWO7KtZXcxYSU2ifSQW8R5BqdfHnMk4qIy';

-- ---------------------------------------------------------------------
-- Perfis
-- ---------------------------------------------------------------------
INSERT INTO perfil (codigo, descricao) VALUES
  ('PARTICIPANTE', 'Participante'),
  ('ORGANIZADOR',  'Organizador'),
  ('STAFF',        'Staff'),
  ('ADMIN',        'Administrador');

-- ---------------------------------------------------------------------
-- Utilizadores
-- ---------------------------------------------------------------------
INSERT INTO utilizador (id_utilizador, nome, email, password_hash, perfil_codigo, idioma, ativo, criado_em) VALUES
  ( 1, 'Ana Administradora', 'admin@festivais.pt',          @hash, 'ADMIN',        'pt', TRUE,  NOW() - INTERVAL 200 DAY),
  ( 2, 'Óscar Organizador',  'organizador1@festivais.pt',   @hash, 'ORGANIZADOR',  'pt', TRUE,  NOW() - INTERVAL 190 DAY),
  ( 3, 'Olga Organizadora',  'organizador2@festivais.pt',   @hash, 'ORGANIZADOR',  'pt', TRUE,  NOW() - INTERVAL 150 DAY),
  ( 4, 'Sérgio Staff',       'staff1@festivais.pt',         @hash, 'STAFF',        'pt', TRUE,  NOW() - INTERVAL 140 DAY),
  ( 5, 'Sofia Staff',        'staff2@festivais.pt',         @hash, 'STAFF',        'pt', TRUE,  NOW() - INTERVAL 140 DAY),
  ( 6, 'Simão Staff',        'staff3@festivais.pt',         @hash, 'STAFF',        'pt', TRUE,  NOW() - INTERVAL 100 DAY),
  ( 7, 'Pedro Pinto',        'participante1@festivais.pt',  @hash, 'PARTICIPANTE', 'pt', TRUE,  NOW() - INTERVAL 130 DAY),
  ( 8, 'Paula Sousa',        'participante2@festivais.pt',  @hash, 'PARTICIPANTE', 'pt', TRUE,  NOW() - INTERVAL 120 DAY),
  ( 9, 'Rita Gomes',         'participante3@festivais.pt',  @hash, 'PARTICIPANTE', 'pt', TRUE,  NOW() - INTERVAL 110 DAY),
  (10, 'Tiago Lopes',        'participante4@festivais.pt',  @hash, 'PARTICIPANTE', 'pt', TRUE,  NOW() - INTERVAL 100 DAY),
  (11, 'Inês Martins',       'participante5@festivais.pt',  @hash, 'PARTICIPANTE', 'pt', TRUE,  NOW() - INTERVAL  90 DAY),
  (12, 'João Ribeiro',       'participante6@festivais.pt',  @hash, 'PARTICIPANTE', 'pt', TRUE,  NOW() - INTERVAL  80 DAY),
  (13, 'Marta Costa',        'participante7@festivais.pt',  @hash, 'PARTICIPANTE', 'pt', TRUE,  NOW() - INTERVAL  40 DAY),
  (14, 'Emma Wilson',        'participante8@festivais.pt',  @hash, 'PARTICIPANTE', 'en', TRUE,  NOW() - INTERVAL  30 DAY),
  (15, 'Carlos Desativado',  'desativado@festivais.pt',     @hash, 'PARTICIPANTE', 'pt', FALSE, NOW() - INTERVAL  60 DAY);

-- ---------------------------------------------------------------------
-- Festivais
--   1 a decorrer hoje        4 terminado
--   2 futuro, inscrições abertas   5 publicado mas desativado (Admin)
--   3 rascunho               6 futuro, lotação esgotada
-- ---------------------------------------------------------------------
INSERT INTO festival (id_festival, id_organizador, nome, descricao, localizacao,
                      data_inicio, data_fim, inscricoes_abrem, inscricoes_fecham,
                      cancelamento_ate, capacidade, preco, estado, ativo, criado_em) VALUES
  (1, 2, 'Sons do Douro',
      'Três dias de música à beira-rio, com pop, folk e fado.',
      'Peso da Régua',
      @hoje - INTERVAL 1 DAY, @hoje + INTERVAL 1 DAY,
      TIMESTAMP(@hoje - INTERVAL 60 DAY, '10:00:00'), TIMESTAMP(@hoje - INTERVAL 2 DAY, '23:59:59'),
      TIMESTAMP(@hoje - INTERVAL 7 DAY, '23:59:59'),
      500, 35.00, 'publicado', TRUE, NOW() - INTERVAL 90 DAY),
  (2, 2, 'Atlântico Fest',
      'Festival de verão junto ao mar, com pop, indie e eletrónica.',
      'Matosinhos',
      @hoje + INTERVAL 30 DAY, @hoje + INTERVAL 32 DAY,
      TIMESTAMP(@hoje - INTERVAL 10 DAY, '10:00:00'), TIMESTAMP(@hoje + INTERVAL 25 DAY, '23:59:59'),
      TIMESTAMP(@hoje + INTERVAL 20 DAY, '23:59:59'),
      1000, 49.90, 'publicado', TRUE, NOW() - INTERVAL 20 DAY),
  (3, 3, 'Noites de Jazz de Braga',
      'Duas noites de jazz num auditório histórico.',
      'Braga',
      @hoje + INTERVAL 60 DAY, @hoje + INTERVAL 61 DAY,
      TIMESTAMP(@hoje + INTERVAL 10 DAY, '10:00:00'), TIMESTAMP(@hoje + INTERVAL 55 DAY, '23:59:59'),
      TIMESTAMP(@hoje + INTERVAL 50 DAY, '23:59:59'),
      300, 25.00, 'rascunho', TRUE, NOW() - INTERVAL 5 DAY),
  (4, 2, 'Rock na Serra',
      'Rock e hard rock em plena serra.',
      'Seia',
      @hoje - INTERVAL 60 DAY, @hoje - INTERVAL 58 DAY,
      TIMESTAMP(@hoje - INTERVAL 120 DAY, '10:00:00'), TIMESTAMP(@hoje - INTERVAL 62 DAY, '23:59:59'),
      TIMESTAMP(@hoje - INTERVAL 70 DAY, '23:59:59'),
      800, 30.00, 'terminado', TRUE, NOW() - INTERVAL 150 DAY),
  (5, 3, 'Eletrónica Algarve',
      'Música eletrónica junto à praia.',
      'Portimão',
      @hoje + INTERVAL 45 DAY, @hoje + INTERVAL 47 DAY,
      TIMESTAMP(@hoje - INTERVAL 5 DAY, '10:00:00'), TIMESTAMP(@hoje + INTERVAL 40 DAY, '23:59:59'),
      TIMESTAMP(@hoje + INTERVAL 35 DAY, '23:59:59'),
      2000, 40.00, 'publicado', FALSE, NOW() - INTERVAL 15 DAY),
  (6, 3, 'Acústico no Jardim',
      'Concertos acústicos ao fim da tarde, com lugares limitados.',
      'Coimbra',
      @hoje + INTERVAL 15 DAY, @hoje + INTERVAL 15 DAY,
      TIMESTAMP(@hoje - INTERVAL 20 DAY, '10:00:00'), TIMESTAMP(@hoje + INTERVAL 10 DAY, '23:59:59'),
      TIMESTAMP(@hoje + INTERVAL 5 DAY, '23:59:59'),
      3, 10.00, 'publicado', TRUE, NOW() - INTERVAL 25 DAY);

-- ---------------------------------------------------------------------
-- Palcos
-- ---------------------------------------------------------------------
INSERT INTO palco (id_palco, id_festival, nome) VALUES
  (1, 1, 'Palco Principal'),
  (2, 1, 'Palco Rio'),
  (3, 2, 'Palco Mar'),
  (4, 2, 'Palco Duna'),
  (5, 3, 'Auditório'),
  (6, 4, 'Palco Serra'),
  (7, 5, 'Palco Sol'),
  (8, 6, 'Coreto');

-- ---------------------------------------------------------------------
-- Artistas (fictícios) e associação aos festivais
-- ---------------------------------------------------------------------
INSERT INTO artista (id_artista, nome, genero, biografia) VALUES
  ( 1, 'Maré Alta',         'Pop rock',    'Banda do Porto com dois álbuns editados.'),
  ( 2, 'Os Navegantes',     'Folk',        'Coletivo de música tradicional com arranjos modernos.'),
  ( 3, 'Luna Ferreira',     'Indie pop',   'Cantora e compositora revelação.'),
  ( 4, 'DJ Cardume',        'Eletrónica',  'DJ e produtor de house e techno.'),
  ( 5, 'Trio Granito',      'Jazz',        'Trio de piano, contrabaixo e bateria.'),
  ( 6, 'Clara Vento',       'Fado',        'Fadista com raízes em Coimbra.'),
  ( 7, 'Sete Colinas',      'Rock',        'Banda de rock alternativo de Lisboa.'),
  ( 8, 'Quarteto Montanha', 'Jazz',        'Quarteto de jazz contemporâneo.'),
  ( 9, 'Neon Lusitano',     'Eletrónica',  'Projeto de synthwave e eletrónica ao vivo.'),
  (10, 'Coro do Vale',      'Tradicional', 'Coro de vozes polifónicas.'),
  (11, 'Ferro Velho',       'Hard rock',   'Banda de hard rock com 20 anos de carreira.'),
  (12, 'Ana Lua',           'Acústico',    'Voz e guitarra em formato intimista.');

INSERT INTO festival_artista (id_festival, id_artista) VALUES
  (1, 1), (1, 2), (1, 6), (1, 7),
  (2, 1), (2, 3), (2, 4), (2, 9),
  (3, 5), (3, 8),
  (4, 2), (4, 7), (4, 11),
  (5, 4), (5, 9),
  (6, 6), (6, 12);

-- ---------------------------------------------------------------------
-- Programação (atuações)
--   Uma atuação pode terminar depois da meia-noite: conta o dia de início.
-- ---------------------------------------------------------------------
INSERT INTO atuacao (id_festival, id_palco, id_artista, inicio, fim) VALUES
  -- Sons do Douro
  (1, 2,  2, TIMESTAMP(@hoje - INTERVAL 1 DAY, '19:00:00'), TIMESTAMP(@hoje - INTERVAL 1 DAY, '20:00:00')),
  (1, 1,  1, TIMESTAMP(@hoje - INTERVAL 1 DAY, '21:00:00'), TIMESTAMP(@hoje - INTERVAL 1 DAY, '22:30:00')),
  (1, 2,  6, TIMESTAMP(@hoje,                  '18:30:00'), TIMESTAMP(@hoje,                  '19:30:00')),
  (1, 1,  7, TIMESTAMP(@hoje,                  '21:00:00'), TIMESTAMP(@hoje,                  '22:30:00')),
  (1, 1,  6, TIMESTAMP(@hoje + INTERVAL 1 DAY, '21:00:00'), TIMESTAMP(@hoje + INTERVAL 1 DAY, '22:00:00')),
  (1, 2,  2, TIMESTAMP(@hoje + INTERVAL 1 DAY, '23:00:00'), TIMESTAMP(@hoje + INTERVAL 2 DAY, '00:30:00')),
  -- Atlântico Fest
  (2, 4,  3, TIMESTAMP(@hoje + INTERVAL 30 DAY, '20:00:00'), TIMESTAMP(@hoje + INTERVAL 30 DAY, '21:00:00')),
  (2, 3,  1, TIMESTAMP(@hoje + INTERVAL 30 DAY, '21:30:00'), TIMESTAMP(@hoje + INTERVAL 30 DAY, '23:00:00')),
  (2, 3,  4, TIMESTAMP(@hoje + INTERVAL 31 DAY, '22:00:00'), TIMESTAMP(@hoje + INTERVAL 31 DAY, '23:59:00')),
  (2, 4,  9, TIMESTAMP(@hoje + INTERVAL 31 DAY, '23:30:00'), TIMESTAMP(@hoje + INTERVAL 32 DAY, '01:00:00')),
  -- Noites de Jazz de Braga
  (3, 5,  5, TIMESTAMP(@hoje + INTERVAL 60 DAY, '21:30:00'), TIMESTAMP(@hoje + INTERVAL 60 DAY, '23:00:00')),
  (3, 5,  8, TIMESTAMP(@hoje + INTERVAL 61 DAY, '21:30:00'), TIMESTAMP(@hoje + INTERVAL 61 DAY, '23:00:00')),
  -- Rock na Serra
  (4, 6,  2, TIMESTAMP(@hoje - INTERVAL 60 DAY, '20:00:00'), TIMESTAMP(@hoje - INTERVAL 60 DAY, '21:30:00')),
  (4, 6, 11, TIMESTAMP(@hoje - INTERVAL 60 DAY, '22:00:00'), TIMESTAMP(@hoje - INTERVAL 60 DAY, '23:30:00')),
  (4, 6,  7, TIMESTAMP(@hoje - INTERVAL 59 DAY, '22:00:00'), TIMESTAMP(@hoje - INTERVAL 59 DAY, '23:30:00')),
  -- Eletrónica Algarve
  (5, 7,  4, TIMESTAMP(@hoje + INTERVAL 45 DAY, '22:00:00'), TIMESTAMP(@hoje + INTERVAL 45 DAY, '23:30:00')),
  (5, 7,  9, TIMESTAMP(@hoje + INTERVAL 46 DAY, '22:00:00'), TIMESTAMP(@hoje + INTERVAL 46 DAY, '23:30:00')),
  -- Acústico no Jardim
  (6, 8, 12, TIMESTAMP(@hoje + INTERVAL 15 DAY, '17:00:00'), TIMESTAMP(@hoje + INTERVAL 15 DAY, '18:00:00')),
  (6, 8,  6, TIMESTAMP(@hoje + INTERVAL 15 DAY, '18:30:00'), TIMESTAMP(@hoje + INTERVAL 15 DAY, '19:30:00'));

-- ---------------------------------------------------------------------
-- Staff associado aos festivais
-- ---------------------------------------------------------------------
INSERT INTO festival_staff (id_festival, id_utilizador, associado_em, ativo) VALUES
  (1, 4, NOW() - INTERVAL 30 DAY, TRUE),
  (1, 5, NOW() - INTERVAL 30 DAY, TRUE),
  (2, 4, NOW() - INTERVAL 10 DAY, TRUE),
  (2, 6, NOW() - INTERVAL 10 DAY, FALSE),   -- associação removida (histórico)
  (4, 5, NOW() - INTERVAL 90 DAY, TRUE),
  (6, 6, NOW() - INTERVAL 15 DAY, TRUE);

-- ---------------------------------------------------------------------
-- Inscrições
-- ---------------------------------------------------------------------
INSERT INTO inscricao (id_inscricao, id_participante, id_festival, estado, valor,
                       criada_em, confirmada_em, cancelada_em) VALUES
  -- Sons do Douro (a decorrer)
  ( 1,  7, 1, 'confirmada', 35.00, NOW() - INTERVAL 50 DAY, NOW() - INTERVAL 50 DAY, NULL),
  ( 2,  8, 1, 'confirmada', 35.00, NOW() - INTERVAL 45 DAY, NOW() - INTERVAL 45 DAY, NULL),
  ( 3,  9, 1, 'confirmada', 35.00, NOW() - INTERVAL 44 DAY, NOW() - INTERVAL 44 DAY, NULL),
  ( 4, 10, 1, 'confirmada', 35.00, NOW() - INTERVAL 40 DAY, NOW() - INTERVAL 40 DAY, NULL),
  ( 5, 11, 1, 'cancelada',  35.00, NOW() - INTERVAL 40 DAY, NOW() - INTERVAL 40 DAY, NOW() - INTERVAL 20 DAY),
  ( 6, 12, 1, 'confirmada', 35.00, NOW() - INTERVAL 30 DAY, NOW() - INTERVAL 30 DAY, NULL),
  -- Atlântico Fest (inscrições abertas)
  ( 7,  7, 2, 'confirmada', 49.90, NOW() - INTERVAL  9 DAY, NOW() - INTERVAL  9 DAY, NULL),
  ( 8,  8, 2, 'pendente',   49.90, NOW() - INTERVAL  8 DAY, NULL, NULL),   -- pagamento recusado
  ( 9,  9, 2, 'pendente',   49.90, NOW() - INTERVAL  2 DAY, NULL, NULL),   -- ainda sem pagamento
  (10, 13, 2, 'confirmada', 49.90, NOW() - INTERVAL  6 DAY, NOW() - INTERVAL  6 DAY, NULL),
  (11, 14, 2, 'confirmada', 49.90, NOW() - INTERVAL  3 DAY, NOW() - INTERVAL  3 DAY, NULL),
  -- Rock na Serra (terminado)
  (12,  7, 4, 'confirmada', 30.00, NOW() - INTERVAL 100 DAY, NOW() - INTERVAL 100 DAY, NULL),
  (13, 10, 4, 'confirmada', 30.00, NOW() - INTERVAL  95 DAY, NOW() - INTERVAL  95 DAY, NULL),
  (14, 12, 4, 'confirmada', 30.00, NOW() - INTERVAL  90 DAY, NOW() - INTERVAL  90 DAY, NULL),
  -- Acústico no Jardim (capacidade 3: esgotado)
  (15,  8, 6, 'confirmada', 10.00, NOW() - INTERVAL 18 DAY, NOW() - INTERVAL 18 DAY, NULL),
  (16, 11, 6, 'confirmada', 10.00, NOW() - INTERVAL 17 DAY, NOW() - INTERVAL 17 DAY, NULL),
  (17, 13, 6, 'confirmada', 10.00, NOW() - INTERVAL 16 DAY, NOW() - INTERVAL 16 DAY, NULL),
  -- Atlântico Fest: inscrição anterior da Emma, cancelada antes da atual (11)
  (18, 14, 2, 'cancelada',  49.90, NOW() - INTERVAL  7 DAY, NOW() - INTERVAL  7 DAY, NOW() - INTERVAL 5 DAY);

-- ---------------------------------------------------------------------
-- Pagamentos simulados (todas as tentativas)
-- ---------------------------------------------------------------------
INSERT INTO pagamento (id_inscricao, metodo, resultado, valor, criado_em) VALUES
  ( 1, 'cartao',     'aprovado', 35.00, NOW() - INTERVAL 50 DAY),
  ( 2, 'mbway',      'aprovado', 35.00, NOW() - INTERVAL 45 DAY),
  ( 3, 'multibanco', 'aprovado', 35.00, NOW() - INTERVAL 44 DAY),
  ( 4, 'cartao',     'aprovado', 35.00, NOW() - INTERVAL 40 DAY),
  ( 5, 'cartao',     'aprovado', 35.00, NOW() - INTERVAL 40 DAY),
  ( 6, 'mbway',      'aprovado', 35.00, NOW() - INTERVAL 30 DAY),
  ( 7, 'cartao',     'aprovado', 49.90, NOW() - INTERVAL  9 DAY),
  ( 8, 'cartao',     'recusado', 49.90, NOW() - INTERVAL  8 DAY),
  (10, 'mbway',      'recusado', 49.90, NOW() - INTERVAL  6 DAY - INTERVAL 1 HOUR),
  (10, 'mbway',      'aprovado', 49.90, NOW() - INTERVAL  6 DAY),
  (18, 'cartao',     'aprovado', 49.90, NOW() - INTERVAL  7 DAY),
  (11, 'cartao',     'aprovado', 49.90, NOW() - INTERVAL  3 DAY),
  (12, 'cartao',     'aprovado', 30.00, NOW() - INTERVAL 100 DAY),
  (13, 'multibanco', 'aprovado', 30.00, NOW() - INTERVAL  95 DAY),
  (14, 'mbway',      'aprovado', 30.00, NOW() - INTERVAL  90 DAY),
  (15, 'cartao',     'aprovado', 10.00, NOW() - INTERVAL 18 DAY),
  (16, 'mbway',      'aprovado', 10.00, NOW() - INTERVAL 17 DAY),
  (17, 'cartao',     'aprovado', 10.00, NOW() - INTERVAL 16 DAY);

-- ---------------------------------------------------------------------
-- Bilhetes (id_bilhete = id_inscricao, para facilitar os testes)
--   Os códigos de demonstração são determinísticos; na aplicação são
--   gerados com bin2hex(random_bytes(32)).
-- ---------------------------------------------------------------------
INSERT INTO bilhete (id_bilhete, id_inscricao, codigo_qr, emitido_em, revogado_em)
SELECT i.id_inscricao,
       i.id_inscricao,
       SHA2(CONCAT('bilhete-demo-', i.id_inscricao), 256),
       i.confirmada_em,
       i.cancelada_em                     -- inscrição cancelada => bilhete revogado
  FROM inscricao i
 WHERE i.confirmada_em IS NOT NULL;

-- ---------------------------------------------------------------------
-- Entradas
--   Sons do Douro: bilhetes 1, 2 e 3 já entraram; 4 e 6 ficam livres
--   para demonstrar a validação ao vivo. Rock na Serra: 12 e 13 entraram.
-- ---------------------------------------------------------------------
INSERT INTO entrada (id_bilhete, id_staff, validada_em) VALUES
  ( 2, 5, TIMESTAMP(@hoje - INTERVAL 1 DAY, '20:15:00')),
  ( 1, 4, TIMESTAMP(@hoje - INTERVAL 1 DAY, '20:40:00')),
  ( 3, 4, TIMESTAMP(@hoje - INTERVAL 1 DAY, '21:05:00')),
  (12, 5, TIMESTAMP(@hoje - INTERVAL 60 DAY, '19:45:00')),
  (13, 5, TIMESTAMP(@hoje - INTERVAL 60 DAY, '20:10:00'));
