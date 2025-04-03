#!/bin/bash

CONTAINER_NAME="wordpress_db"
DB_USER="wordpress"
DB_PASSWORD="wordpress"
DB_NAME="wordpress"
BACKUP_FILE="db_backup_$(date +%Y%m%d_%H%M%S).sql"

function show_help() {
    echo "Usage: $0"
    echo "Effectue une sauvegarde de la base de données MySQL contenue dans un conteneur Docker."
    echo ""
    echo "Options :"
    echo "  -h   Affiche cette aide"
    exit 0
}

if [ "$1" == "-h" ]; then
    show_help
fi

echo "🔄 Sauvegarde de la base de données..."

# Execution de mysqldump via une image MySQL externe car non present dans limage mariadb:latest
docker run --rm --network container:"$CONTAINER_NAME" mysql:latest \
    mysqldump -h 127.0.0.1 -u "$DB_USER" -p"$DB_PASSWORD" "$DB_NAME" > "$BACKUP_FILE"

if [ $? -eq 0 ]; then
    echo "✅ Sauvegarde réussie : $BACKUP_FILE"
else
    echo "❌ Erreur lors de la sauvegarde !" >&2
    rm $BACKUP_FILE
    exit 1
fi
