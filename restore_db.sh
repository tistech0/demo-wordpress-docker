#!/bin/bash

# Définition des variables
CONTAINER_NAME="wordpress_db"
DB_USER="wordpress"
DB_PASSWORD="wordpress"
DB_NAME="wordpress"
BACKUP_FILE="$1"

function show_help() {
    echo "Usage: $0 <backup_file.sql>"
    echo "Restaure une base de données MySQL depuis un fichier de sauvegarde."
    echo ""
    echo "Options :"
    echo "  -h   Affiche cette aide"
    exit 0
}

if [ -z "$BACKUP_FILE" ] || [ "$BACKUP_FILE" == "-h" ]; then
    show_help
fi

if [ ! -f "$BACKUP_FILE" ]; then
    echo "❌ Erreur : le fichier de sauvegarde '$BACKUP_FILE' n'existe pas !" >&2
    exit 1
fi

echo "🔄 Restauration de la base de données depuis $BACKUP_FILE..."

# Utilisation de docker run avec une image MySQL extern pour la restauration
# Le volume est monte pour que limage mysql puisse acceder au fichier de sauvegarde
docker run --rm --network container:"$CONTAINER_NAME" \
    -v "$(pwd)/$BACKUP_FILE:/backup.sql" \
    mysql:latest \
    sh -c "mysql -h 127.0.0.1 -u \"$DB_USER\" -p\"$DB_PASSWORD\" \"$DB_NAME\" < /backup.sql"

if [ $? -eq 0 ]; then
    echo "✅ Restauration réussie depuis $BACKUP_FILE"
else
    echo "❌ Erreur lors de la restauration !" >&2
    exit 1
fi