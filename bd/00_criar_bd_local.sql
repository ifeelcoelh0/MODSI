-- =====================================================================
--  00_criar_bd_local.sql — SÓ PARA DESENVOLVIMENTO LOCAL
--  Cria (ou recria) a base de dados "festivais". No servidor final a base
--  de dados normalmente já vem criada; nesse caso este ficheiro não se usa.
-- =====================================================================
DROP DATABASE IF EXISTS festivais;
CREATE DATABASE festivais
  CHARACTER SET utf8mb4
  COLLATE utf8mb4_unicode_ci;   -- pesquisa sem distinguir maiúsculas nem acentos
