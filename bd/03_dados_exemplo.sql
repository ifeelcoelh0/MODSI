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
