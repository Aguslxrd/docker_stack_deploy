#!/bin/bash

# directorios de las instancias
WORKDIR="$HOME/docker"
NEXTCLOUD_DIR="$WORKDIR/nextcloud"
NGINX_PROXY_MANAGER_DIR="$WORKDIR/nginx-proxy-manager"
PORTAINER_DIR="$WORKDIR/portainer"
n
mkdir -p $NEXTCLOUD_DIR
mkdir -p $NGINX_PROXY_MANAGER_DIR
mkdir -p $PORTAINER_DIR

#docker-compose para nextcloud
cat <<EOF > $NEXTCLOUD_DIR/docker-compose.yml
version: '3'

services:
  nextcloud:
    image: nextcloud
    container_name: nextcloud
    ports:
      - "8080:80"
    volumes:
      - nextcloud_data:/var/www/html
    environment:
      - MYSQL_PASSWORD=your_password
      - MYSQL_DATABASE=nextcloud
      - MYSQL_USER=nextcloud
      - MYSQL_HOST=db
    depends_on:
      - db

  db:
    image: mariadb
    container_name: nextcloud_db
    environment:
      - MYSQL_ROOT_PASSWORD=your_password
    volumes:
      - db_data:/var/lib/mysql

volumes:
  nextcloud_data:
  db_data:
EOF

#docker-compose para nginx proxy manager
cat <<EOF > $NGINX_PROXY_MANAGER_DIR/docker-compose.yml
version: '3'

services:
  app:
    image: 'jc21/nginx-proxy-manager:latest'
    container_name: nginx_proxy_manager
    restart: unless-stopped
    ports:
      - '80:80'
      - '81:81'
      - '443:443'
    environment:
      DB_MYSQL_HOST: "db"
      DB_MYSQL_PORT: 3306
      DB_MYSQL_USER: "npm"
      DB_MYSQL_PASSWORD: "your_password"
      DB_MYSQL_NAME: "npm"
    volumes:
      - ./data:/data
      - ./letsencrypt:/etc/letsencrypt
    depends_on:
      - db

  db:
    image: mariadb:latest
    container_name: nginx_proxy_manager_db
    environment:
      MYSQL_ROOT_PASSWORD: 'your_password'
      MYSQL_DATABASE: 'npm'
      MYSQL_USER: 'npm'
      MYSQL_PASSWORD: 'your_password'
    volumes:
      - ./db:/var/lib/mysql
EOF

#docker-compose para portainer
cat <<EOF > $PORTAINER_DIR/docker-compose.yml
version: '3'

services:
  portainer:
    image: portainer/portainer-ce
    container_name: portainer
    restart: always
    command: -H unix:///var/run/docker.sock
    volumes:
      - /var/run/docker.sock:/var/run/docker.sock
      - portainer_data:/data
    ports:
      - "9000:9000"

volumes:
  portainer_data:
EOF

# deploy de cada instancia
deploy_service() {
    echo "Desplegando $1..."
    docker-compose -f $2 up -d
}

deploy_service "Nextcloud" "$NEXTCLOUD_DIR/docker-compose.yml"
deploy_service "Nginx Proxy Manager" "$NGINX_PROXY_MANAGER_DIR/docker-compose.yml"
deploy_service "Portainer" "$PORTAINER_DIR/docker-compose.yml"

echo "Instancias desplegadas."
