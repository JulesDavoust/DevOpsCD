#!/bin/bash
set -e

read -p "Enter your docker username : " DOCKER_USERNAME
read -sp "Enter your docker password : " DOCKER_PASSWORD
# Variables
# DOCKER_USERNAME="fowx"
# DOCKER_PASSWORD="dckr_pat_G4R1zoQYUVnEhBBwb2onAAYUEQU"

# Connexion à Docker Hub
echo "Logging in to Docker Hub..."
echo "$DOCKER_PASSWORD" | docker login -u "$DOCKER_USERNAME" --password-stdin || {
    echo "Docker login failed. Exiting script."
    exit 1
}

REPO_FRONTEND=''
REPO_API=''
REPO_BDD=''
# Chemin vers le fichier .env
ENV_FILE=".env"

# Liste des services et variables associées
declare -A services
services=( ["FRONTEND_IMAGE"]="frontend" ["API_IMAGE"]="api" ["DATABASE_IMAGE"]="database" )

# Boucle pour chaque service
for var in "${!services[@]}"; do
    echo "Enter your Docker repository that you want to use for the ${services[$var]} image : "
    read -p "$DOCKER_USERNAME/" REPO
    if [ ${services[$var]} == "frontend" ]; then
        REPO_FRONTEND="$DOCKER_USERNAME/$REPO"
    elif [ ${services[$var]} == "api" ]; then
        REPO_API="$DOCKER_USERNAME/$REPO"
    elif [ ${services[$var]} == "database" ]; then
        REPO_BDD="$DOCKER_USERNAME/$REPO"
    fi
    read -p "Enter the image's tag that you want to launch : " tagImage
    # Modifier uniquement la variable dans le fichier .env
    sed -i "s/^$var=.*/$var=$DOCKER_USERNAME\/$REPO:$tagImage/" "$ENV_FILE"
done


echo "Mise à jour des images dans $ENV_FILE terminée."


# Rentrer repo Docker
# echo "Enter your docker repository for the frontend image : "
# read -p "$DOCKER_USERNAME/" REPO_FRONTEND

# REPO_FRONTEND="$DOCKER_USERNAME/$REPO_FRONTEND"

# echo "Enter your docker repository for the API image : "
# read -p "$DOCKER_USERNAME/" REPO_API

# REPO_API="$DOCKER_USERNAME/$REPO_API"

# echo "Enter your docker repository for the BDD image : "
# read -p "$DOCKER_USERNAME/" REPO_BDD

# REPO_BDD="$DOCKER_USERNAME/$REPO_BDD"

# Construire les images
echo "Building images with Docker Compose..."
docker-compose build || {
    echo "Docker Compose build failed. Exiting script."
    exit 1
}

echo "$REPO_FRONTEND $REPO_API $REPO_BDD"

read -p "Do you want to push the images to Docker Hub ? (y/n) " pushImagesVar
# Pousser les images vers Docker Hub
if [ $pushImagesVar == "y" ]; then
    services2=("$REPO_FRONTEND" "$REPO_API" "$REPO_BDD")
    for service2 in "${services2[@]}"; do
        echo "service : $service2"
        read -p "Insert the tag that you want to have for your $service2 image : " tagImageVar
        IMAGE_TAG="$service2:$tagImageVar"
        echo "$IMAGE_TAG"
        docker tag "$service2" "$IMAGE_TAG" || {
            echo "Failed to tag image for $service2. Exiting script."
            exit 1
        }
        docker images
        echo "Tagging and pushing image for $service2..."
        docker push "$IMAGE_TAG" || {
            echo "Failed to push image for $service2. Exiting script."
            exit 1
        }
    done
fi

read -p "Do you want to start the docker containers ? (y/n) " startContainerVar

if [ $startContainerVar == "y" ]; then
    # Démarrer les services
    echo "Starting services with Docker Compose..."
    docker-compose up -d || {
        echo "Failed to start services. Exiting script."
        exit 1
    }
    # Vérification des services
    echo "Verifying services are running..."
    docker-compose ps
    echo "All services started successfully!"
else
    echo "Exiting script."
fi


