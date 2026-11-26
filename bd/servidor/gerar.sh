#!/bin/sh
# Gera importar_no_servidor.sql a partir de ../01, ../02 e ../03.
# Uso: sh gerar.sh [nome_da_base]   (por omissão: 1211154)
BASE="${1:-1211154}"
cd "$(dirname "$0")"
{
cat <<EOF
-- =====================================================================
--  Sistema de Gestão de Festivais — IMPORTAÇÃO NO SERVIDOR DO ISEP
--  phpmyadmin.dee.isep.ipp.pt (MariaDB 10.11) — base de dados: $BASE
--
--  Como usar: phpMyAdmin → separador "Importar" → escolher este ficheiro
--  → "Importar". A linha USE abaixo escolhe a base de dados do grupo.
--  Junta 01_esquema.sql + 02_vistas.sql + 03_dados_exemplo.sql.
--  ATENÇÃO: apaga e recria as tabelas da aplicação (os dados voltam ao
--  estado inicial). Ficheiro gerado por gerar.sh — alterar os 01–03.
-- =====================================================================

USE \`$BASE\`;
EOF
for f in 01_esquema.sql 02_vistas.sql 03_dados_exemplo.sql; do
  printf '\n-- >>>>>>>>>>>>>>>> %s <<<<<<<<<<<<<<<<\n' "$f"
  cat "../$f"
done
} > importar_no_servidor.sql
echo "gerado: importar_no_servidor.sql (base $BASE)"
