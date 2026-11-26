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
