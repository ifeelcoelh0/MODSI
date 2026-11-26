-- =====================================================================
--  Sistema de Gestão de Festivais — MODSI 2026/2027
--  04_consultas.sql : consultas SQL por caso de uso
--
--  As variáveis @... fazem o papel dos parâmetros que a aplicação passa
--  ao PDO (ex.: @festival -> :festival). Os valores por omissão
--  funcionam com 03_dados_exemplo.sql.
--
--  As operações com várias escritas (inscrever, pagar, cancelar, validar
--  entrada) aparecem como a SEQUÊNCIA de instruções que o PHP executa
--  dentro de uma transação PDO:
--      $pdo->beginTransaction(); ... $pdo->commit();   (rollBack() em erro)
--  "SELECT ... FOR UPDATE" bloqueia a linha até ao commit. Ordem de
--  bloqueio sempre festival -> inscricao, para evitar deadlocks.
-- =====================================================================
SET NAMES utf8mb4 COLLATE utf8mb4_unicode_ci;   -- igual à collation das tabelas

SET @festival     = 2;      -- Atlântico Fest
SET @participante = 7;      -- Pedro Pinto
SET @organizador  = 2;      -- Óscar Organizador
SET @staff        = 4;      -- Sérgio Staff
SET @pesquisa     = 'fest';
SET @local        = 'Matosinhos';
SET @data_de      = CURDATE();
SET @data_ate     = CURDATE() + INTERVAL 90 DAY;
SET @email        = 'participante1@festivais.pt';
SET @limite = 10, @offset = 0;   -- paginação (RNF12)

-- =====================================================================
--  VISITANTE
-- =====================================================================

-- UC01 — Lista de festivais públicos (paginada)
--   No PDO, LIMIT/OFFSET passam como parâmetros inteiros.
SELECT id_festival, nome, localizacao, data_inicio, data_fim, preco,
       lugares_disponiveis, inscricoes_abertas
  FROM vw_festivais_publicos
 WHERE data_fim >= CURDATE()
 ORDER BY data_inicio
 LIMIT 10 OFFSET 0;

-- UC02 + UC03 — Pesquisa por nome e filtros por data/localização (AJAX)
--   Cada filtro é opcional: NULL desativa-o.
SELECT id_festival, nome, localizacao, data_inicio, data_fim, preco, lugares_disponiveis
  FROM vw_festivais_publicos
 WHERE (@pesquisa IS NULL OR nome LIKE CONCAT('%', @pesquisa, '%'))
   AND (@local    IS NULL OR localizacao LIKE CONCAT('%', @local, '%'))
   AND (@data_de  IS NULL OR data_fim    >= @data_de)
   AND (@data_ate IS NULL OR data_inicio <= @data_ate)
 ORDER BY data_inicio;

-- Lista de localizações para o filtro (caixa de seleção)
SELECT DISTINCT localizacao FROM vw_festivais_publicos ORDER BY localizacao;

-- UC04 — Detalhes de um festival
SELECT * FROM vw_festivais_publicos WHERE id_festival = @festival;

-- UC05 — Programação por dia e palco
SELECT dia, palco, artista, genero,
       TIME_FORMAT(inicio, '%H:%i') AS hora_inicio,
       TIME_FORMAT(fim,    '%H:%i') AS hora_fim
  FROM vw_programacao
 WHERE id_festival = @festival
 ORDER BY dia, inicio, palco;

-- UC05 — Artistas do festival (com biografia)
SELECT a.id_artista, a.nome, a.genero, a.biografia
  FROM festival_artista fa
  JOIN artista a ON a.id_artista = fa.id_artista
 WHERE fa.id_festival = @festival
 ORDER BY a.nome;

-- UC06 — Registar conta (perfil Participante por omissão, RN01)
--   O hash é gerado em PHP com password_hash(); erro 1062 => email já registado.
-- INSERT INTO utilizador (nome, email, password_hash, idioma)
-- VALUES (:nome, :email, :hash, :idioma);

-- =====================================================================
--  UTILIZADOR AUTENTICADO
-- =====================================================================

-- UC07 — Iniciar sessão: obter a conta pelo email; a palavra-passe é
--   verificada em PHP com password_verify(). Conta inativa => recusar (RN02).
SELECT id_utilizador, nome, password_hash, perfil_codigo, idioma, ativo
  FROM utilizador
 WHERE email = @email;

-- UC09 — Editar perfil
-- UPDATE utilizador SET nome = :nome, idioma = :idioma WHERE id_utilizador = :id;
-- UPDATE utilizador SET password_hash = :hash WHERE id_utilizador = :id;

-- =====================================================================
--  PARTICIPANTE
-- =====================================================================

-- UC10 — Inscrever-se  (TRANSAÇÃO no PHP; RN05, RN06, RN07)
--   0. Na sessão: perfil = PARTICIPANTE e conta ativa (RN01, RN02).
--   1. Bloquear o festival (serializa inscrições e pagamentos do festival):
--      SELECT estado, ativo, inscricoes_abrem, inscricoes_fecham, capacidade, preco
--        FROM festival WHERE id_festival = :festival FOR UPDATE;
--      -> sem linha: FESTIVAL_INEXISTENTE
--      -> estado <> 'publicado' OU NOT ativo OU agora fora do período: INSCRICOES_FECHADAS
--   2. SELECT COUNT(*) FROM inscricao WHERE id_festival = :festival AND estado = 'confirmada';
--      -> >= capacidade: LOTACAO_ESGOTADA
--   3. SELECT id_inscricao FROM inscricao
--       WHERE id_participante = :participante AND id_festival = :festival AND estado <> 'cancelada';
--      -> existe: INSCRICAO_DUPLICADA (a UNIQUE uk_inscricao_ativa também o impede)
--   4. INSERT INTO inscricao (id_participante, id_festival, valor)
--      VALUES (:participante, :festival, :preco);        -- preço lido no passo 1
--      $id = $pdo->lastInsertId();
--   5. COMMIT

-- UC11 — Pagamento simulado  (TRANSAÇÃO no PHP; RN08, RN09)
--   O resultado ('aprovado'/'recusado') é decidido pela simulação no PHP.
--   1. SELECT id_festival FROM inscricao WHERE id_inscricao = :inscricao;
--   2. SELECT capacidade FROM festival WHERE id_festival = :festival FOR UPDATE;
--   3. SELECT id_participante, estado, valor FROM inscricao
--       WHERE id_inscricao = :inscricao FOR UPDATE;
--      -> id_participante <> utilizador da sessão: INSCRICAO_INEXISTENTE
--      -> estado <> 'pendente': INSCRICAO_NAO_PENDENTE
--   4. Se aprovado: contar confirmadas (como em UC10, passo 2) -> LOTACAO_ESGOTADA
--   5. INSERT INTO pagamento (id_inscricao, metodo, resultado, valor)
--      VALUES (:inscricao, :metodo, :resultado, :valor);
--   6. Se aprovado:
--      UPDATE inscricao SET estado = 'confirmada', confirmada_em = NOW()
--       WHERE id_inscricao = :inscricao;
--      INSERT INTO bilhete (id_inscricao, codigo_qr)
--      VALUES (:inscricao, :codigo);          -- :codigo = bin2hex(random_bytes(32))
--   7. COMMIT   (se recusado, o commit grava só a tentativa)

-- UC12 — As minhas inscrições
SELECT id_inscricao, festival, localizacao, data_inicio, data_fim,
       estado, valor, criada_em, confirmada_em, entrou, pode_cancelar
  FROM vw_inscricoes_detalhe
 WHERE id_participante = @participante
 ORDER BY data_inicio DESC;

-- UC11 — Histórico de tentativas de pagamento de uma inscrição
SELECT p.id_pagamento, p.metodo, p.resultado, p.valor, p.criado_em
  FROM pagamento p
  JOIN inscricao i ON i.id_inscricao = p.id_inscricao
 WHERE i.id_participante = @participante
 ORDER BY p.criado_em DESC;

-- UC13 — Bilhete QR (só do próprio participante e não revogado)
SELECT id_inscricao, festival, localizacao, data_inicio, data_fim,
       participante, codigo_qr, entrou
  FROM vw_inscricoes_detalhe
 WHERE id_participante = @participante
   AND estado = 'confirmada'
   AND revogado_em IS NULL;

-- UC14 — Cancelar inscrição  (TRANSAÇÃO no PHP; RN10)
--   1. SELECT id_festival FROM inscricao WHERE id_inscricao = :inscricao;
--   2. SELECT cancelamento_ate FROM festival WHERE id_festival = :festival FOR UPDATE;
--   3. SELECT id_participante, estado FROM inscricao WHERE id_inscricao = :inscricao FOR UPDATE;
--      -> não é do utilizador: INSCRICAO_INEXISTENTE
--      -> 'cancelada': INSCRICAO_JA_CANCELADA
--      -> NOW() > cancelamento_ate: PRAZO_CANCELAMENTO_ULTRAPASSADO
--   4. SELECT 1 FROM entrada e JOIN bilhete b ON b.id_bilhete = e.id_bilhete
--       WHERE b.id_inscricao = :inscricao;
--      -> existe: ENTRADA_JA_REGISTADA
--   5. UPDATE inscricao SET estado = 'cancelada', cancelada_em = NOW() WHERE id_inscricao = :inscricao;
--      UPDATE bilhete SET revogado_em = NOW() WHERE id_inscricao = :inscricao AND revogado_em IS NULL;
--   6. COMMIT

-- =====================================================================
--  ORGANIZADOR  (todas as operações filtram id_organizador — RN04)
-- =====================================================================

-- Os meus festivais, com ocupação
SELECT id_festival, nome, estado, ativo, data_inicio, data_fim,
       capacidade, confirmadas, pendentes, taxa_ocupacao, receita
  FROM vw_ocupacao_festival
 WHERE id_organizador = @organizador
 ORDER BY data_inicio DESC;

-- UC15 — Criar festival (fica em rascunho)
-- INSERT INTO festival (id_organizador, nome, descricao, localizacao, data_inicio, data_fim,
--                       inscricoes_abrem, inscricoes_fecham, cancelamento_ate, capacidade, preco)
-- VALUES (:org, :nome, :descricao, :localizacao, :inicio, :fim, :abrem, :fecham, :cancelamento, :capacidade, :preco);

-- UC16 — Editar festival: a capacidade não pode descer abaixo das confirmadas
-- UPDATE festival f
--    SET f.nome = :nome, f.capacidade = :capacidade, ...
--  WHERE f.id_festival = :festival AND f.id_organizador = :org
--    AND f.estado IN ('rascunho', 'publicado')
--    AND :capacidade >= (SELECT COUNT(*) FROM inscricao i
--                         WHERE i.id_festival = f.id_festival AND i.estado = 'confirmada');
--   0 linhas afetadas => mostrar o erro adequado.

-- UC16 — Alterar estado (transições permitidas do diagrama de estados)
-- UPDATE festival SET estado = 'publicado'
--  WHERE id_festival = :festival AND id_organizador = :org AND estado = 'rascunho';
-- UPDATE festival SET estado = 'cancelado'
--  WHERE id_festival = :festival AND id_organizador = :org AND estado IN ('rascunho','publicado');
-- UPDATE festival SET estado = 'terminado'
--  WHERE id_festival = :festival AND id_organizador = :org AND estado = 'publicado';

-- UC17 — Palcos do festival, com número de atuações (só remove se 0, RN14)
SELECT p.id_palco, p.nome, COUNT(a.id_atuacao) AS atuacoes
  FROM palco p
  JOIN festival f ON f.id_festival = p.id_festival
  LEFT JOIN atuacao a ON a.id_palco = p.id_palco
 WHERE p.id_festival = @festival AND f.id_organizador = @organizador
 GROUP BY p.id_palco, p.nome
 ORDER BY p.nome;

-- UC18 — Pesquisar artistas do catálogo que ainda não estão no festival
SET @pesquisa_a = 'quarteto';
SELECT a.id_artista, a.nome, a.genero
  FROM artista a
 WHERE a.nome LIKE CONCAT('%', @pesquisa_a, '%')
   AND NOT EXISTS (SELECT 1 FROM festival_artista fa
                    WHERE fa.id_festival = @festival AND fa.id_artista = a.id_artista)
 ORDER BY a.nome;

-- UC18 — Associar / desassociar artista
-- INSERT INTO festival_artista (id_festival, id_artista) VALUES (:festival, :artista);
-- DELETE FROM festival_artista WHERE id_festival = :festival AND id_artista = :artista;
--   (erro 1451 => tem atuações marcadas, RN14)

-- UC19 — Programação para edição
SELECT id_atuacao, dia, inicio, fim, palco, artista
  FROM vw_programacao
 WHERE id_festival = @festival
 ORDER BY inicio;
-- UC19 — Validações antes de gravar uma atuação (RN13), feitas no PHP:
--   fim > inicio (o CHECK ck_atuacao_horario também o garante)
--   ATUACAO_FORA_DATAS: o dia de início está dentro das datas do festival
SET @palco = 1, @inicio = TIMESTAMP(CURDATE(), '21:30:00'), @fim = TIMESTAMP(CURDATE(), '22:00:00'),
    @atuacao = 0;   -- 0 ao criar; id da atuação ao editar
SELECT (DATE(@inicio) BETWEEN data_inicio AND data_fim) AS dentro_das_datas
  FROM festival WHERE id_festival = 1;
--   ATUACAO_SOBREPOSTA: outra atuação no mesmo palco que se cruza no tempo
SELECT COUNT(*) AS sobreposicoes
  FROM atuacao
 WHERE id_palco = @palco
   AND id_atuacao <> @atuacao
   AND inicio < @fim AND fim > @inicio;
-- INSERT INTO atuacao (id_festival, id_palco, id_artista, inicio, fim)
-- VALUES (:festival, :palco, :artista, :inicio, :fim);
--   Erro 1452 => palco ou artista não pertencem ao festival (FKs compostas)

-- UC20 — Staff do festival
SELECT u.id_utilizador, u.nome, u.email, fs.associado_em, fs.ativo
  FROM festival_staff fs
  JOIN utilizador u ON u.id_utilizador = fs.id_utilizador
 WHERE fs.id_festival = @festival
 ORDER BY fs.ativo DESC, u.nome;

-- UC20 — Associar (ou reativar) / remover membro do Staff
--   Antes: o utilizador existe e tem perfil STAFF (senão UTILIZADOR_NAO_STAFF)
-- SELECT id_utilizador FROM utilizador WHERE email = :email AND perfil_codigo = 'STAFF' AND ativo = TRUE;
-- INSERT INTO festival_staff (id_festival, id_utilizador) VALUES (:festival, :staff)
--   ON DUPLICATE KEY UPDATE ativo = TRUE, associado_em = NOW();
-- UPDATE festival_staff SET ativo = FALSE WHERE id_festival = :festival AND id_utilizador = :staff;

-- UC21 — Inscrições do festival (filtro opcional por estado)
SET @estado = NULL;
SELECT id_inscricao, participante, email, estado, valor, criada_em, confirmada_em, entrou
  FROM vw_inscricoes_detalhe
 WHERE id_festival = @festival
   AND (@estado IS NULL OR estado = @estado)
 ORDER BY criada_em DESC;

-- UC21 — Indicadores do festival
SELECT capacidade, confirmadas, pendentes, canceladas, entradas, taxa_ocupacao, receita
  FROM vw_ocupacao_festival
 WHERE id_festival = @festival AND id_organizador = @organizador;

-- UC21 — Gráfico: inscrições confirmadas por dia
SELECT DATE(confirmada_em) AS dia, COUNT(*) AS inscricoes
  FROM inscricao
 WHERE id_festival = @festival AND estado = 'confirmada'
 GROUP BY DATE(confirmada_em)
 ORDER BY dia;

-- =====================================================================
--  STAFF  (todas as operações exigem associação ativa — RN12)
-- =====================================================================

-- UC22 — Festivais associados (os de hoje primeiro)
SELECT f.id_festival, f.nome, f.localizacao, f.data_inicio, f.data_fim,
       (CURDATE() BETWEEN f.data_inicio AND f.data_fim) AS decorre_hoje
  FROM festival_staff fs
  JOIN festival f ON f.id_festival = fs.id_festival
 WHERE fs.id_utilizador = @staff AND fs.ativo = TRUE
 ORDER BY decorre_hoje DESC, f.data_inicio;

-- UC23 — Participantes inscritos (pesquisa por nome, email ou código)
SET @festival_staff = 1;
SELECT v.participante, v.email, LEFT(v.codigo_qr, 8) AS codigo_curto, v.entrou, v.entrada_em
  FROM vw_inscricoes_detalhe v
 WHERE v.id_festival = @festival_staff
   AND v.estado = 'confirmada'
   AND EXISTS (SELECT 1 FROM festival_staff fs
                WHERE fs.id_festival = v.id_festival
                  AND fs.id_utilizador = @staff AND fs.ativo = TRUE)
   AND (@pesquisa_p IS NULL
        OR v.participante LIKE CONCAT('%', @pesquisa_p, '%')
        OR v.email        LIKE CONCAT('%', @pesquisa_p, '%')
        OR v.codigo_qr    LIKE CONCAT(@pesquisa_p, '%'))
 ORDER BY v.participante;

-- UC24 — Verificar bilhete (AJAX; RN11, RN12)
--   a) O Staff está associado a este festival?  -> senão STAFF_NAO_ASSOCIADO
SELECT 1 AS associado
  FROM festival_staff fs
  JOIN utilizador u ON u.id_utilizador = fs.id_utilizador
 WHERE fs.id_festival = @festival_staff AND fs.id_utilizador = @staff
   AND fs.ativo = TRUE AND u.perfil_codigo = 'STAFF' AND u.ativo = TRUE;

--   b) Dados do bilhete. O PHP verifica, por esta ordem:
--      sem linha                        -> BILHETE_INEXISTENTE
--      id_festival <> festival do Staff -> BILHETE_OUTRO_FESTIVAL
--      revogado_em IS NOT NULL          -> BILHETE_REVOGADO
--      estado <> 'confirmada'           -> INSCRICAO_NAO_CONFIRMADA
--      entrada_em IS NOT NULL           -> BILHETE_JA_UTILIZADO (mostrar entrada_em)
--      decorre_hoje = 0                 -> FESTIVAL_NAO_DECORRE
--      caso contrário                   -> VALIDO
SET @codigo = SHA2('bilhete-demo-4', 256);      -- bilhete do Tiago, Sons do Douro
SELECT b.id_bilhete, i.id_festival, i.estado, b.revogado_em,
       u.nome AS participante, e.validada_em AS entrada_em,
       (CURDATE() BETWEEN f.data_inicio AND f.data_fim) AS decorre_hoje
  FROM bilhete b
  JOIN inscricao  i ON i.id_inscricao  = b.id_inscricao
  JOIN utilizador u ON u.id_utilizador = i.id_participante
  JOIN festival   f ON f.id_festival   = i.id_festival
  LEFT JOIN entrada e ON e.id_bilhete  = b.id_bilhete
 WHERE b.codigo_qr = @codigo;

-- UC25 — Validar entrada: repetir UC24 e, se VALIDO,
-- INSERT INTO entrada (id_bilhete, id_staff) VALUES (:bilhete, :staff);
--   Erro 1062 (UNIQUE uk_entrada_bilhete) => outro posto validou o mesmo
--   bilhete ao mesmo tempo: responder BILHETE_JA_UTILIZADO.

-- UC26 — Histórico de entradas e contador
SELECT validada_em, participante, staff
  FROM vw_entradas_detalhe
 WHERE id_festival = @festival_staff
 ORDER BY validada_em DESC;

SELECT confirmadas, entradas FROM vw_ocupacao_festival WHERE id_festival = @festival_staff;

-- =====================================================================
--  ADMINISTRADOR
-- =====================================================================

-- UC27 — Contas (pesquisa e filtros opcionais)
SET @perfil = NULL, @ativo = NULL;
SELECT u.id_utilizador, u.nome, u.email, p.descricao AS perfil, u.ativo, u.criado_em
  FROM utilizador u
  JOIN perfil p ON p.codigo = u.perfil_codigo
 WHERE (@pesquisa_u IS NULL OR u.nome LIKE CONCAT('%', @pesquisa_u, '%')
                            OR u.email LIKE CONCAT('%', @pesquisa_u, '%'))
   AND (@perfil IS NULL OR u.perfil_codigo = @perfil)
   AND (@ativo  IS NULL OR u.ativo = @ativo)
 ORDER BY u.nome
 LIMIT 10 OFFSET 0;

-- UC27 — Ativar/desativar (o administrador não se desativa a si próprio)
-- UPDATE utilizador SET ativo = :ativo WHERE id_utilizador = :id AND id_utilizador <> :admin_atual;

-- UC28 — Atribuir perfil (verificações feitas antes, na aplicação):
--   Organizador com festivais publicados:
SELECT COUNT(*) AS festivais_publicados FROM festival
 WHERE id_organizador = @organizador AND estado = 'publicado';
--   Último administrador ativo:
SELECT COUNT(*) AS administradores_ativos FROM utilizador
 WHERE perfil_codigo = 'ADMIN' AND ativo = TRUE;
-- UPDATE utilizador SET perfil_codigo = :perfil WHERE id_utilizador = :id;
--   Se deixou de ser Staff:
-- UPDATE festival_staff SET ativo = FALSE WHERE id_utilizador = :id;

-- UC29 — Todos os festivais
SELECT o.id_festival, o.nome, u.nome AS organizador, o.estado, o.ativo,
       o.data_inicio, o.data_fim, o.confirmadas, o.capacidade
  FROM vw_ocupacao_festival o
  JOIN utilizador u ON u.id_utilizador = o.id_organizador
 ORDER BY o.data_inicio DESC;

-- UC30 — Ativar/desativar festival
-- UPDATE festival SET ativo = :ativo WHERE id_festival = :festival;

-- UC31 — Indicadores globais
SELECT * FROM vw_indicadores_globais;

-- UC31 — Gráficos por período
SELECT perfil_codigo, COUNT(*) AS total FROM utilizador GROUP BY perfil_codigo;

SELECT DATE_FORMAT(criado_em, '%Y-%m') AS mes,
       SUM(resultado = 'aprovado') AS aprovados,
       SUM(resultado = 'recusado') AS recusados,
       SUM(CASE WHEN resultado = 'aprovado' THEN valor ELSE 0 END) AS receita
  FROM pagamento
 WHERE criado_em >= CURDATE() - INTERVAL 12 MONTH
 GROUP BY mes
 ORDER BY mes;
