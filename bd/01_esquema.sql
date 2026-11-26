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
