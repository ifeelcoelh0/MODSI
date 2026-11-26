# Base de dados — Sistema de Gestão de Festivais

**Versão mínima**: pensada para funcionar mesmo num alojamento limitado. Usa só tabelas, chaves, `UNIQUE`, `CHECK`, colunas geradas e vistas, **sem triggers nem procedimentos**. As regras que precisam de lógica são garantidas pelo PHP, com transações PDO.

Compatível com MySQL 5.7+ e MariaDB 10.2+ (o do XAMPP). As restrições `CHECK` só são aplicadas a partir de MySQL 8.0.16 ou MariaDB 10.2.

> **Testado a 2026-11-23 em MySQL 8.0.46** (Ubuntu): os scripts 00 a 04 correm sem erros e os 54 testes do `05_testes.sql` passam. Ainda não foi testado em MariaDB/XAMPP.

| Ficheiro | Onde | Conteúdo |
|---|---|---|
| `00_criar_bd_local.sql` | só local | cria ou recria a base `festivais` |
| `01_esquema.sql` | local e servidor | 12 tabelas e restrições (apaga as tabelas, se já existirem) |
| `02_vistas.sql` | local e servidor | 6 vistas `vw_*` usadas pela aplicação |
| `03_dados_exemplo.sql` | local e servidor | dados de demonstração, com datas relativas ao dia de execução |
| `04_consultas.sql` | referência | consultas e sequências das transações por caso de uso (UC01–UC31), para passar para o PHP |
| `05_testes.sql` | só local | 54 testes às restrições e à coerência dos dados (**altera os dados**) |
| `opcional/triggers_procedimentos.sql` | não usado | versão com a lógica dentro da BD, para mais tarde, se o servidor o permitir. Criar triggers exige privilégio SUPER ou `log_bin_trust_function_creators = 1` (com um utilizador normal dá o erro 1419) |

## Executar em local

```bash
cd MODSI/bd
mysql -u root -p < 00_criar_bd_local.sql
mysql -u root -p festivais < 01_esquema.sql
mysql -u root -p festivais < 02_vistas.sql
mysql -u root -p festivais < 03_dados_exemplo.sql
mysql -u root -p festivais --table < 05_testes.sql   # opcional: no fim mostra OK/FALHA
```

Depois dos testes, voltem a correr os passos 01 a 03 para repor os dados.

**phpMyAdmin**: criem a base de dados, selecionem-na e importem o 01, o 02 e o 03, por esta ordem.

**Servidor final**: selecionem a base de dados que vos derem e importem o 01, o 02 e o 03. Se o servidor não deixar criar vistas, importem só o 01 e o 03; as consultas das vistas passam então para os Models do PHP.

## Dump para entrega

```bash
mysqldump -u root -p festivais > festivais_dump.sql
```

## Regras que o PHP tem de garantir

A base de dados já impede: inscrições ativas duplicadas (RN06), mais de um pagamento aprovado por inscrição (RN08), bilhetes e códigos QR repetidos (RN09), mais de uma entrada por bilhete (RN11), atuações com palco ou artista de outro festival (RN13) e a remoção de palcos ou artistas com atuações (RN14).

O resto fica a cargo do PHP. As consultas exatas estão no `04_consultas.sql`.

| Regra | Onde |
|---|---|
| RN01/RN02 perfil e conta ativa em cada pedido | sessão + verificação no Controller |
| RN03/RN05 festival publicado, ativo, dentro do período e com lugares | UC10, em transação |
| RN04 o organizador só mexe nos seus festivais | `WHERE id_organizador = :sessao` |
| RN07 valor = preço no momento da inscrição | UC10 |
| RN08/RN09 pagamento, confirmação e bilhete juntos | UC11, em transação |
| RN10 prazo de cancelamento e bilhete revogado | UC14, em transação |
| RN11 bilhete válido e festival a decorrer hoje | UC24/UC25 |
| RN12 Staff com perfil STAFF e associado ao festival | UC20, UC23–UC26 |
| RN13 sem sobreposição e dentro das datas do festival | UC19 |

**Ligação PDO**: usem a mesma *collation* das tabelas, senão o MySQL 8 pode dar o erro 1267 (*Illegal mix of collations*):

```php
$pdo = new PDO("mysql:host=$host;dbname=$bd;charset=utf8mb4", $user, $pass, [
    PDO::ATTR_ERRMODE => PDO::ERRMODE_EXCEPTION,
    PDO::MYSQL_ATTR_INIT_COMMAND => "SET NAMES utf8mb4 COLLATE utf8mb4_unicode_ci",
]);
```

Os erros de negócio devem ter um código (por exemplo `LOTACAO_ESGOTADA`), usado como chave de tradução PT/EN.

## Contas de demonstração (palavra-passe `Demo1234!`)

| Email | Perfil |
|---|---|
| admin@festivais.pt | Administrador |
| organizador1@festivais.pt | Organizador (Sons do Douro, Atlântico Fest, Rock na Serra) |
| organizador2@festivais.pt | Organizador (Jazz de Braga, Eletrónica Algarve, Acústico no Jardim) |
| staff1@festivais.pt | Staff (Sons do Douro, Atlântico Fest) |
| staff2@festivais.pt | Staff (Sons do Douro, Rock na Serra) |
| staff3@festivais.pt | Staff (Acústico no Jardim) |
| participante1..8@festivais.pt | Participante (o 8 usa a interface em inglês) |
| desativado@festivais.pt | conta desativada (o login tem de falhar) |

## Festivais de demonstração

| # | Festival | Situação |
|---|---|---|
| 1 | Sons do Douro | **a decorrer hoje**: para validar entradas (bilhetes 4 e 6 ainda não entraram) |
| 2 | Atlântico Fest | futuro, inscrições abertas; tem inscrições pendentes e um pagamento recusado |
| 3 | Noites de Jazz de Braga | rascunho (não aparece ao público) |
| 4 | Rock na Serra | terminado (histórico) |
| 5 | Eletrónica Algarve | publicado mas **desativado** pelo Administrador |
| 6 | Acústico no Jardim | **esgotado** (capacidade 3) |

Os códigos QR de demonstração são `SHA2('bilhete-demo-N', 256)`, em que N é o número da inscrição. Para os ver:

```sql
SELECT id_inscricao, participante, festival, codigo_qr FROM vw_inscricoes_detalhe WHERE codigo_qr IS NOT NULL;
```

Na aplicação, o código é gerado com `bin2hex(random_bytes(32))`.
