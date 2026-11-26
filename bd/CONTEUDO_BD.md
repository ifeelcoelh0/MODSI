# Conteúdo da base de dados `festivais`

Gerado a 2026-11-23 a partir da base local, depois de correr `bd/01`, `02` e `03`. As datas dos dados de exemplo são **relativas ao dia em que o `03_dados_exemplo.sql` é executado**; noutro dia, os valores mudam.

| Tabela | Colunas | Linhas |
|---|---|---|
| [perfil](#perfil) | 2 | 4 |
| [utilizador](#utilizador) | 8 | 15 |
| [festival](#festival) | 15 | 6 |
| [festival_staff](#festival_staff) | 4 | 6 |
| [artista](#artista) | 4 | 12 |
| [festival_artista](#festival_artista) | 2 | 17 |
| [palco](#palco) | 3 | 8 |
| [atuacao](#atuacao) | 6 | 19 |
| [inscricao](#inscricao) | 9 | 18 |
| [pagamento](#pagamento) | 7 | 18 |
| [bilhete](#bilhete) | 5 | 16 |
| [entrada](#entrada) | 4 | 5 |
| **Total** | 69 | 144 |

## perfil

Tipos de conta (RN01).

**Colunas**

| Coluna | Tipo | Chave | Nulo | Por omissão / extra |
|---|---|---|---|---|
| `codigo` | varchar(20) | PK | não |  |
| `descricao` | varchar(100) |  | não |  |

**Linhas (4)**

| codigo | descricao |
|---|---|
| ADMIN | Administrador |
| ORGANIZADOR | Organizador |
| PARTICIPANTE | Participante |
| STAFF | Staff |

## utilizador

Contas de todos os perfis. Palavra-passe de demonstração: `Demo1234!` (só o *hash* é guardado).

**Colunas**

| Coluna | Tipo | Chave | Nulo | Por omissão / extra |
|---|---|---|---|---|
| `id_utilizador` | bigint unsigned | PK | não | auto_increment |
| `nome` | varchar(120) |  | não |  |
| `email` | varchar(254) | UK | não |  |
| `password_hash` | varchar(255) |  | não |  |
| `perfil_codigo` | varchar(20) | índice, FK → perfil.codigo | não | PARTICIPANTE |
| `idioma` | char(2) |  | não | pt |
| `ativo` | tinyint(1) |  | não | 1 |
| `criado_em` | datetime |  | não | CURRENT_TIMESTAMP |

**Linhas (15)**

| id_utilizador | nome | email | password_hash | perfil_codigo | idioma | ativo | criado_em |
|---|---|---|---|---|---|---|---|
| 1 | Ana Administradora | admin@festivais.pt | $2y$10$VD52L… | ADMIN | pt | 1 | 2026-05-07 14:45:07 |
| 2 | Óscar Organizador | organizador1@festivais.pt | $2y$10$VD52L… | ORGANIZADOR | pt | 1 | 2026-05-17 14:45:07 |
| 3 | Olga Organizadora | organizador2@festivais.pt | $2y$10$VD52L… | ORGANIZADOR | pt | 1 | 2026-06-26 14:45:07 |
| 4 | Sérgio Staff | staff1@festivais.pt | $2y$10$VD52L… | STAFF | pt | 1 | 2026-07-06 14:45:07 |
| 5 | Sofia Staff | staff2@festivais.pt | $2y$10$VD52L… | STAFF | pt | 1 | 2026-07-06 14:45:07 |
| 6 | Simão Staff | staff3@festivais.pt | $2y$10$VD52L… | STAFF | pt | 1 | 2026-08-15 14:45:07 |
| 7 | Pedro Pinto | participante1@festivais.pt | $2y$10$VD52L… | PARTICIPANTE | pt | 1 | 2026-07-16 14:45:07 |
| 8 | Paula Sousa | participante2@festivais.pt | $2y$10$VD52L… | PARTICIPANTE | pt | 1 | 2026-07-26 14:45:07 |
| 9 | Rita Gomes | participante3@festivais.pt | $2y$10$VD52L… | PARTICIPANTE | pt | 1 | 2026-08-05 14:45:07 |
| 10 | Tiago Lopes | participante4@festivais.pt | $2y$10$VD52L… | PARTICIPANTE | pt | 1 | 2026-08-15 14:45:07 |
| 11 | Inês Martins | participante5@festivais.pt | $2y$10$VD52L… | PARTICIPANTE | pt | 1 | 2026-08-25 14:45:07 |
| 12 | João Ribeiro | participante6@festivais.pt | $2y$10$VD52L… | PARTICIPANTE | pt | 1 | 2026-09-04 14:45:07 |
| 13 | Marta Costa | participante7@festivais.pt | $2y$10$VD52L… | PARTICIPANTE | pt | 1 | 2026-10-14 14:45:07 |
| 14 | Emma Wilson | participante8@festivais.pt | $2y$10$VD52L… | PARTICIPANTE | en | 1 | 2026-10-24 14:45:07 |
| 15 | Carlos Desativado | desativado@festivais.pt | $2y$10$VD52L… | PARTICIPANTE | pt | 0 | 2026-09-24 14:45:07 |

## festival

`estado` é gerido pelo Organizador; `ativo` é gerido pelo Administrador (RN03).

**Colunas**

| Coluna | Tipo | Chave | Nulo | Por omissão / extra |
|---|---|---|---|---|
| `id_festival` | bigint unsigned | PK | não | auto_increment |
| `id_organizador` | bigint unsigned | índice, FK → utilizador.id_utilizador | não |  |
| `nome` | varchar(160) | índice | não |  |
| `descricao` | text |  | sim |  |
| `localizacao` | varchar(200) | índice | não |  |
| `data_inicio` | date |  | não |  |
| `data_fim` | date |  | não |  |
| `inscricoes_abrem` | datetime |  | não |  |
| `inscricoes_fecham` | datetime |  | não |  |
| `cancelamento_ate` | datetime |  | não |  |
| `capacidade` | int unsigned |  | não |  |
| `preco` | decimal(10,2) |  | não | 0.00 |
| `estado` | enum('rascunho','publicado','cancelado','terminado') | índice | não | rascunho |
| `ativo` | tinyint(1) |  | não | 1 |
| `criado_em` | datetime |  | não | CURRENT_TIMESTAMP |

**Linhas (6)**

| id_festival | id_organizador | nome | descricao | localizacao | data_inicio | data_fim | inscricoes_abrem | inscricoes_fecham | cancelamento_ate | capacidade | preco | estado | ativo | criado_em |
|---|---|---|---|---|---|---|---|---|---|---|---|---|---|---|
| 1 | 2 | Sons do Douro | Três dias de música à beira-rio, com pop, … | Peso da Régua | 2026-11-22 | 2026-11-24 | 2026-09-24 10:00:00 | 2026-11-21 23:59:59 | 2026-11-16 23:59:59 | 500 | 35.00 | publicado | 1 | 2026-08-25 14:45:07 |
| 2 | 2 | Atlântico Fest | Festival de verão junto ao mar, com pop, i… | Matosinhos | 2026-12-23 | 2026-12-25 | 2026-11-13 10:00:00 | 2026-12-18 23:59:59 | 2026-12-13 23:59:59 | 1000 | 49.90 | publicado | 1 | 2026-11-03 14:45:07 |
| 3 | 3 | Noites de Jazz de Braga | Duas noites de jazz num auditório histórico. | Braga | 2027-01-22 | 2027-01-23 | 2026-12-03 10:00:00 | 2027-01-17 23:59:59 | 2027-01-12 23:59:59 | 300 | 25.00 | rascunho | 1 | 2026-11-18 14:45:07 |
| 4 | 2 | Rock na Serra | Rock e hard rock em plena serra. | Seia | 2026-09-24 | 2026-09-26 | 2026-07-26 10:00:00 | 2026-09-22 23:59:59 | 2026-09-14 23:59:59 | 800 | 30.00 | terminado | 1 | 2026-06-26 14:45:07 |
| 5 | 3 | Eletrónica Algarve | Música eletrónica junto à praia. | Portimão | 2027-01-07 | 2027-01-09 | 2026-11-18 10:00:00 | 2027-01-02 23:59:59 | 2026-12-28 23:59:59 | 2000 | 40.00 | publicado | 0 | 2026-11-08 14:45:07 |
| 6 | 3 | Acústico no Jardim | Concertos acústicos ao fim da tarde, com l… | Coimbra | 2026-12-08 | 2026-12-08 | 2026-11-03 10:00:00 | 2026-12-03 23:59:59 | 2026-11-28 23:59:59 | 3 | 10.00 | publicado | 1 | 2026-10-29 14:45:07 |

## festival_staff

Staff associado a cada festival. Remover = `ativo` 0 (RN12).

**Colunas**

| Coluna | Tipo | Chave | Nulo | Por omissão / extra |
|---|---|---|---|---|
| `id_festival` | bigint unsigned | PK, FK → festival.id_festival | não |  |
| `id_utilizador` | bigint unsigned | PK, FK → utilizador.id_utilizador | não |  |
| `associado_em` | datetime |  | não | CURRENT_TIMESTAMP |
| `ativo` | tinyint(1) |  | não | 1 |

**Linhas (6)**

| id_festival | id_utilizador | associado_em | ativo |
|---|---|---|---|
| 1 | 4 | 2026-10-24 14:45:07 | 1 |
| 1 | 5 | 2026-10-24 14:45:07 | 1 |
| 2 | 4 | 2026-11-13 14:45:07 | 1 |
| 2 | 6 | 2026-11-13 14:45:07 | 0 |
| 4 | 5 | 2026-08-25 14:45:07 | 1 |
| 6 | 6 | 2026-11-08 14:45:07 | 1 |

## artista

Catálogo de artistas (fictícios), partilhado por todos os festivais.

**Colunas**

| Coluna | Tipo | Chave | Nulo | Por omissão / extra |
|---|---|---|---|---|
| `id_artista` | bigint unsigned | PK | não | auto_increment |
| `nome` | varchar(160) | índice | não |  |
| `genero` | varchar(80) |  | sim |  |
| `biografia` | text |  | sim |  |

**Linhas (12)**

| id_artista | nome | genero | biografia |
|---|---|---|---|
| 1 | Maré Alta | Pop rock | Banda do Porto com dois álbuns editados. |
| 2 | Os Navegantes | Folk | Coletivo de música tradicional com arranjo… |
| 3 | Luna Ferreira | Indie pop | Cantora e compositora revelação. |
| 4 | DJ Cardume | Eletrónica | DJ e produtor de house e techno. |
| 5 | Trio Granito | Jazz | Trio de piano, contrabaixo e bateria. |
| 6 | Clara Vento | Fado | Fadista com raízes em Coimbra. |
| 7 | Sete Colinas | Rock | Banda de rock alternativo de Lisboa. |
| 8 | Quarteto Montanha | Jazz | Quarteto de jazz contemporâneo. |
| 9 | Neon Lusitano | Eletrónica | Projeto de synthwave e eletrónica ao vivo. |
| 10 | Coro do Vale | Tradicional | Coro de vozes polifónicas. |
| 11 | Ferro Velho | Hard rock | Banda de hard rock com 20 anos de carreira. |
| 12 | Ana Lua | Acústico | Voz e guitarra em formato intimista. |

## festival_artista

Que artistas participam em cada festival (N:M).

**Colunas**

| Coluna | Tipo | Chave | Nulo | Por omissão / extra |
|---|---|---|---|---|
| `id_festival` | bigint unsigned | PK, FK → festival.id_festival | não |  |
| `id_artista` | bigint unsigned | PK, FK → artista.id_artista | não |  |

**Linhas (17)**

| id_festival | id_artista |
|---|---|
| 1 | 1 |
| 2 | 1 |
| 1 | 2 |
| 4 | 2 |
| 2 | 3 |
| 2 | 4 |
| 5 | 4 |
| 3 | 5 |
| 1 | 6 |
| 6 | 6 |
| 1 | 7 |
| 4 | 7 |
| 3 | 8 |
| 2 | 9 |
| 5 | 9 |
| 4 | 11 |
| 6 | 12 |

## palco

Palcos de cada festival.

**Colunas**

| Coluna | Tipo | Chave | Nulo | Por omissão / extra |
|---|---|---|---|---|
| `id_palco` | bigint unsigned | PK | não | auto_increment |
| `id_festival` | bigint unsigned | índice, FK → festival.id_festival | não |  |
| `nome` | varchar(100) |  | não |  |

**Linhas (8)**

| id_palco | id_festival | nome |
|---|---|---|
| 1 | 1 | Palco Principal |
| 2 | 1 | Palco Rio |
| 4 | 2 | Palco Duna |
| 3 | 2 | Palco Mar |
| 5 | 3 | Auditório |
| 6 | 4 | Palco Serra |
| 7 | 5 | Palco Sol |
| 8 | 6 | Coreto |

## atuacao

Programação: artista + palco + horário (RN13).

**Colunas**

| Coluna | Tipo | Chave | Nulo | Por omissão / extra |
|---|---|---|---|---|
| `id_atuacao` | bigint unsigned | PK | não | auto_increment |
| `id_festival` | bigint unsigned | índice, FK → festival_artista.id_festival, palco.id_festival | não |  |
| `id_palco` | bigint unsigned | índice, FK → palco.id_palco | não |  |
| `id_artista` | bigint unsigned | FK → festival_artista.id_artista | não |  |
| `inicio` | datetime |  | não |  |
| `fim` | datetime |  | não |  |

**Linhas (19)**

| id_atuacao | id_festival | id_palco | id_artista | inicio | fim |
|---|---|---|---|---|---|
| 1 | 1 | 2 | 2 | 2026-11-22 19:00:00 | 2026-11-22 20:00:00 |
| 2 | 1 | 1 | 1 | 2026-11-22 21:00:00 | 2026-11-22 22:30:00 |
| 3 | 1 | 2 | 6 | 2026-11-23 18:30:00 | 2026-11-23 19:30:00 |
| 4 | 1 | 1 | 7 | 2026-11-23 21:00:00 | 2026-11-23 22:30:00 |
| 5 | 1 | 1 | 6 | 2026-11-24 21:00:00 | 2026-11-24 22:00:00 |
| 6 | 1 | 2 | 2 | 2026-11-24 23:00:00 | 2026-11-25 00:30:00 |
| 7 | 2 | 4 | 3 | 2026-12-23 20:00:00 | 2026-12-23 21:00:00 |
| 8 | 2 | 3 | 1 | 2026-12-23 21:30:00 | 2026-12-23 23:00:00 |
| 9 | 2 | 3 | 4 | 2026-12-24 22:00:00 | 2026-12-24 23:59:00 |
| 10 | 2 | 4 | 9 | 2026-12-24 23:30:00 | 2026-12-25 01:00:00 |
| 11 | 3 | 5 | 5 | 2027-01-22 21:30:00 | 2027-01-22 23:00:00 |
| 12 | 3 | 5 | 8 | 2027-01-23 21:30:00 | 2027-01-23 23:00:00 |
| 13 | 4 | 6 | 2 | 2026-09-24 20:00:00 | 2026-09-24 21:30:00 |
| 14 | 4 | 6 | 11 | 2026-09-24 22:00:00 | 2026-09-24 23:30:00 |
| 15 | 4 | 6 | 7 | 2026-09-25 22:00:00 | 2026-09-25 23:30:00 |
| 16 | 5 | 7 | 4 | 2027-01-07 22:00:00 | 2027-01-07 23:30:00 |
| 17 | 5 | 7 | 9 | 2027-01-08 22:00:00 | 2027-01-08 23:30:00 |
| 18 | 6 | 8 | 12 | 2026-12-08 17:00:00 | 2026-12-08 18:00:00 |
| 19 | 6 | 8 | 6 | 2026-12-08 18:30:00 | 2026-12-08 19:30:00 |

## inscricao

`id_festival_ativa` é uma coluna gerada: impede duas inscrições não canceladas no mesmo festival (RN06).

**Colunas**

| Coluna | Tipo | Chave | Nulo | Por omissão / extra |
|---|---|---|---|---|
| `id_inscricao` | bigint unsigned | PK | não | auto_increment |
| `id_participante` | bigint unsigned | índice, FK → utilizador.id_utilizador | não |  |
| `id_festival` | bigint unsigned | índice, FK → festival.id_festival | não |  |
| `estado` | enum('pendente','confirmada','cancelada') |  | não | pendente |
| `valor` | decimal(10,2) |  | não |  |
| `criada_em` | datetime |  | não | CURRENT_TIMESTAMP |
| `confirmada_em` | datetime |  | sim |  |
| `cancelada_em` | datetime |  | sim |  |
| `id_festival_ativa` | bigint unsigned |  | sim | coluna gerada |

**Linhas (18)**

| id_inscricao | id_participante | id_festival | estado | valor | criada_em | confirmada_em | cancelada_em | id_festival_ativa |
|---|---|---|---|---|---|---|---|---|
| 1 | 7 | 1 | confirmada | 35.00 | 2026-10-04 14:45:07 | 2026-10-04 14:45:07 | — | 1 |
| 2 | 8 | 1 | confirmada | 35.00 | 2026-10-09 14:45:07 | 2026-10-09 14:45:07 | — | 1 |
| 3 | 9 | 1 | confirmada | 35.00 | 2026-10-10 14:45:07 | 2026-10-10 14:45:07 | — | 1 |
| 4 | 10 | 1 | confirmada | 35.00 | 2026-10-14 14:45:07 | 2026-10-14 14:45:07 | — | 1 |
| 5 | 11 | 1 | cancelada | 35.00 | 2026-10-14 14:45:07 | 2026-10-14 14:45:07 | 2026-11-03 14:45:07 | — |
| 6 | 12 | 1 | confirmada | 35.00 | 2026-10-24 14:45:07 | 2026-10-24 14:45:07 | — | 1 |
| 7 | 7 | 2 | confirmada | 49.90 | 2026-11-14 14:45:07 | 2026-11-14 14:45:07 | — | 2 |
| 8 | 8 | 2 | pendente | 49.90 | 2026-11-15 14:45:07 | — | — | 2 |
| 9 | 9 | 2 | pendente | 49.90 | 2026-11-21 14:45:07 | — | — | 2 |
| 10 | 13 | 2 | confirmada | 49.90 | 2026-11-17 14:45:07 | 2026-11-17 14:45:07 | — | 2 |
| 11 | 14 | 2 | confirmada | 49.90 | 2026-11-20 14:45:07 | 2026-11-20 14:45:07 | — | 2 |
| 12 | 7 | 4 | confirmada | 30.00 | 2026-08-15 14:45:07 | 2026-08-15 14:45:07 | — | 4 |
| 13 | 10 | 4 | confirmada | 30.00 | 2026-08-20 14:45:07 | 2026-08-20 14:45:07 | — | 4 |
| 14 | 12 | 4 | confirmada | 30.00 | 2026-08-25 14:45:07 | 2026-08-25 14:45:07 | — | 4 |
| 15 | 8 | 6 | confirmada | 10.00 | 2026-11-05 14:45:07 | 2026-11-05 14:45:07 | — | 6 |
| 16 | 11 | 6 | confirmada | 10.00 | 2026-11-06 14:45:07 | 2026-11-06 14:45:07 | — | 6 |
| 17 | 13 | 6 | confirmada | 10.00 | 2026-11-07 14:45:07 | 2026-11-07 14:45:07 | — | 6 |
| 18 | 14 | 2 | cancelada | 49.90 | 2026-11-16 14:45:07 | 2026-11-16 14:45:07 | 2026-11-18 14:45:07 | — |

## pagamento

Todas as tentativas de pagamento simulado. `inscricao_aprovada` (gerada) impede dois pagamentos aprovados (RN08).

**Colunas**

| Coluna | Tipo | Chave | Nulo | Por omissão / extra |
|---|---|---|---|---|
| `id_pagamento` | bigint unsigned | PK | não | auto_increment |
| `id_inscricao` | bigint unsigned | índice, FK → inscricao.id_inscricao | não |  |
| `metodo` | enum('cartao','mbway','multibanco') |  | não |  |
| `resultado` | enum('aprovado','recusado') |  | não |  |
| `valor` | decimal(10,2) |  | não |  |
| `criado_em` | datetime | índice | não | CURRENT_TIMESTAMP |
| `inscricao_aprovada` | bigint unsigned | UK | sim | coluna gerada |

**Linhas (18)**

| id_pagamento | id_inscricao | metodo | resultado | valor | criado_em | inscricao_aprovada |
|---|---|---|---|---|---|---|
| 1 | 1 | cartao | aprovado | 35.00 | 2026-10-04 14:45:07 | 1 |
| 2 | 2 | mbway | aprovado | 35.00 | 2026-10-09 14:45:07 | 2 |
| 3 | 3 | multibanco | aprovado | 35.00 | 2026-10-10 14:45:07 | 3 |
| 4 | 4 | cartao | aprovado | 35.00 | 2026-10-14 14:45:07 | 4 |
| 5 | 5 | cartao | aprovado | 35.00 | 2026-10-14 14:45:07 | 5 |
| 6 | 6 | mbway | aprovado | 35.00 | 2026-10-24 14:45:07 | 6 |
| 7 | 7 | cartao | aprovado | 49.90 | 2026-11-14 14:45:07 | 7 |
| 8 | 8 | cartao | recusado | 49.90 | 2026-11-15 14:45:07 | — |
| 9 | 10 | mbway | recusado | 49.90 | 2026-11-17 13:45:07 | — |
| 10 | 10 | mbway | aprovado | 49.90 | 2026-11-17 14:45:07 | 10 |
| 11 | 18 | cartao | aprovado | 49.90 | 2026-11-16 14:45:07 | 18 |
| 12 | 11 | cartao | aprovado | 49.90 | 2026-11-20 14:45:07 | 11 |
| 13 | 12 | cartao | aprovado | 30.00 | 2026-08-15 14:45:07 | 12 |
| 14 | 13 | multibanco | aprovado | 30.00 | 2026-08-20 14:45:07 | 13 |
| 15 | 14 | mbway | aprovado | 30.00 | 2026-08-25 14:45:07 | 14 |
| 16 | 15 | cartao | aprovado | 10.00 | 2026-11-05 14:45:07 | 15 |
| 17 | 16 | mbway | aprovado | 10.00 | 2026-11-06 14:45:07 | 16 |
| 18 | 17 | cartao | aprovado | 10.00 | 2026-11-07 14:45:07 | 17 |

## bilhete

Um por inscrição confirmada, com código QR único (RN09). `revogado_em` preenchido = cancelado.

**Colunas**

| Coluna | Tipo | Chave | Nulo | Por omissão / extra |
|---|---|---|---|---|
| `id_bilhete` | bigint unsigned | PK | não | auto_increment |
| `id_inscricao` | bigint unsigned | UK, FK → inscricao.id_inscricao | não |  |
| `codigo_qr` | char(64) | UK | não |  |
| `emitido_em` | datetime |  | não | CURRENT_TIMESTAMP |
| `revogado_em` | datetime |  | sim |  |

**Linhas (16)**

| id_bilhete | id_inscricao | codigo_qr | emitido_em | revogado_em |
|---|---|---|---|---|
| 1 | 1 | b6ec565b7085… | 2026-10-04 14:45:07 | — |
| 2 | 2 | 7423b668a0f1… | 2026-10-09 14:45:07 | — |
| 3 | 3 | c19d1bce6a7f… | 2026-10-10 14:45:07 | — |
| 4 | 4 | 6217cc481352… | 2026-10-14 14:45:07 | — |
| 5 | 5 | 016cebc5d1d0… | 2026-10-14 14:45:07 | 2026-11-03 14:45:07 |
| 6 | 6 | 579f6101eef7… | 2026-10-24 14:45:07 | — |
| 7 | 7 | 724adb081dea… | 2026-11-14 14:45:07 | — |
| 10 | 10 | 56f37eb07eed… | 2026-11-17 14:45:07 | — |
| 11 | 11 | cbb1f0fd8dcc… | 2026-11-20 14:45:07 | — |
| 12 | 12 | 49a0188091ff… | 2026-08-15 14:45:07 | — |
| 13 | 13 | 20d5ef35fc7e… | 2026-08-20 14:45:07 | — |
| 14 | 14 | d45a26ba6348… | 2026-08-25 14:45:07 | — |
| 15 | 15 | 3772b7c8668e… | 2026-11-05 14:45:07 | — |
| 16 | 16 | ce7f0b7b8fc7… | 2026-11-06 14:45:07 | — |
| 17 | 17 | 39aff2bfd25f… | 2026-11-07 14:45:07 | — |
| 18 | 18 | 50beb4a57c3e… | 2026-11-16 14:45:07 | 2026-11-18 14:45:07 |

## entrada

Entradas validadas pelo Staff. No máximo uma por bilhete (RN11).

**Colunas**

| Coluna | Tipo | Chave | Nulo | Por omissão / extra |
|---|---|---|---|---|
| `id_entrada` | bigint unsigned | PK | não | auto_increment |
| `id_bilhete` | bigint unsigned | UK, FK → bilhete.id_bilhete | não |  |
| `id_staff` | bigint unsigned | índice, FK → utilizador.id_utilizador | não |  |
| `validada_em` | datetime | índice | não | CURRENT_TIMESTAMP |

**Linhas (5)**

| id_entrada | id_bilhete | id_staff | validada_em |
|---|---|---|---|
| 1 | 2 | 5 | 2026-11-22 20:15:00 |
| 2 | 1 | 4 | 2026-11-22 20:40:00 |
| 3 | 3 | 4 | 2026-11-22 21:05:00 |
| 4 | 12 | 5 | 2026-09-24 19:45:00 |
| 5 | 13 | 5 | 2026-09-24 20:10:00 |
