# WordPress Docker Demo

Voici un guide simple pour déployer une démo WordPress avec Docker et restaurer des sauvegardes de base de données.

## Installation et configuration

## 1. Démarrer l'environnement Docker

1. Cloner le référentiel et entrer dans le dossier :
   ```bash
   git clone https://github.com/tistech0/demo-wordpress-docker.git
   cd demo-wordpress-docker
   ```
2. Lancer les conteneurs :
   ```bash
   docker-compose up -d
   ```
   - Attendez quelques instants que les services (WordPress, MariaDB, Adminer) se lancent.

## 2. Accéder à l'interface WordPress

1. Ouvrir un navigateur et aller sur : [http://localhost:8080](http://localhost:8080)
2. **Ne pas effectuer le setup manuellement**, la restauration de la base de données à l'étape suivante prendra en charge la configuration.

## 3. Restaurer la première sauvegarde

1. Exécuter la commande :
   ```bash
   ./restore_db.sh EXAMPLE_1_db_backup_20250403_231345.sql
   ```
2. Recharger la page WordPress (à l'adresse [http://localhost:8080](http://localhost:8080)).
3. Identifiez-vous avec :
   - **Utilisateur** : docker
   - **Mot de passe** : docker
4. Vous accédez maintenant à l'accueil du site WordPress.

## 4. Restaurer la seconde sauvegarde

1. Exécuter la commande :
   ```bash
   ./restore_db.sh EXAMPLE_2_db_backup_20250403_231419.sql
   ```
2. Recharger la page d'accueil de WordPress.
3. Le titre du blog est maintenant modifié en **"Blog modifié"**.

## 5. Fin de la démonstration

Vous venez d'installer WordPress avec Docker et de restaurer des sauvegardes pour modifier son contenu automatiquement. Pour arrêter les services :
```bash
docker-compose down
```
Cela supprimera également les volumes associés, y compris la base de données.
Si besoin, relancez-les avec docker-compose up -d. La configuration sera à refaire ou à recharger.

## 6. **Accéder aux services**
   - WordPress : http://localhost:8080
   - Adminer (gestion de BDD) : http://localhost:8081
     - Serveur : db
     - Utilisateur : wordpress
     - Mot de passe : wordpress
     - Base de données : wordpress

## Sauvegarde de la base de données
```bash
./save_db.sh
```

## Structure du projet

### Docker Compose

Le fichier `docker-compose.yml` définit trois services principaux :

```yaml
services:
  wordpress:
    image: wordpress:latest
    container_name: wordpress
    restart: always
    ports:
      - "8080:80"
    environment:
      WORDPRESS_DB_HOST: db
      WORDPRESS_DB_USER: wordpress
      WORDPRESS_DB_PASSWORD: wordpress
      WORDPRESS_DB_NAME: wordpress
    volumes:
      - ./wordpress:/var/www/html
```
**Service WordPress** : Utilise l'image officielle WordPress, exposée sur le port 8080 et configurée pour se connecter au service de base de données `db`. Les fichiers WordPress sont persistés dans le dossier local `./wordpress`.

```yaml
  db:
    image: mariadb:latest
    container_name: wordpress_db
    restart: always
    environment:
      MYSQL_ROOT_PASSWORD: rootpassword
      MYSQL_DATABASE: wordpress
      MYSQL_USER: wordpress
      MYSQL_PASSWORD: wordpress
    volumes:
      - db_data:/var/lib/mysql
```
**Service Base de données** : Utilise MariaDB pour stocker les données WordPress. Un volume nommé `db_data` est utilisé pour persister les données de la base.

```yaml
  adminer:
    image: adminer:latest
    container_name: adminer
    restart: always
    ports:
      - "8081:8080"
    environment:
      ADMINER_DEFAULT_SERVER: db
```
**Service Adminer** : Interface graphique pour gérer la base de données, accessible sur le port 8081.

```yaml
volumes:
  db_data:
```
**Définition du volume** : Crée un volume Docker nommé qui persiste entre les redémarrages.

### Scripts de sauvegarde et restauration

#### Script de restauration (restore_db.sh)

```bash
#!/bin/bash

# Définition des variables
CONTAINER_NAME="wordpress_db"
DB_USER="wordpress"
DB_PASSWORD="wordpress"
DB_NAME="wordpress"
BACKUP_FILE="$1"
```
**Variables de configuration** : Définit les paramètres pour se connecter à la base de données MariaDB et le fichier de sauvegarde à utiliser.

```bash
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
```
**Validation des entrées** : Vérifie que le fichier de sauvegarde est spécifié et existe, sinon affiche l'aide ou une erreur.

```bash
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
```
**Exécution de la restauration** : Utilise une image MySQL temporaire qui se connecte en réseau au conteneur de base de données. Le fichier de sauvegarde est monté dans le conteneur temporaire et la commande `mysql` est exécutée pour importer les données.

#### Script de sauvegarde (save_db.sh)

```bash
#!/bin/bash

CONTAINER_NAME="wordpress_db"
DB_USER="wordpress"
DB_PASSWORD="wordpress"
DB_NAME="wordpress"
BACKUP_FILE="db_backup_$(date +%Y%m%d_%H%M%S).sql"
```
**Variables de configuration** : Définit les paramètres pour se connecter à la base de données et génère un nom de fichier de sauvegarde unique basé sur la date et l'heure actuelles.

```bash
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
```
**Aide utilisateur** : Fournit une aide si l'option `-h` est spécifiée.

```bash
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
```
**Exécution de la sauvegarde** : Utilise une image MySQL temporaire qui se connecte en réseau au conteneur de base de données. La commande `mysqldump` est exécutée pour extraire les données et les enregistrer dans un fichier local. En cas d'erreur, le fichier partiel est supprimé.