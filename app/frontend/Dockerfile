# Étape 1 : Construction du frontend
FROM node:20.11.0 AS builder
WORKDIR /app
COPY package.json package-lock.json ./
USER root
RUN npm install
COPY . .
RUN npm run build

# Étape 2 : Image finale pour servir les fichiers statiques
FROM nginx:alpine
COPY --from=builder /app/dist /usr/share/nginx/html

# Ajout du fichier template env.js
COPY ./src/env.template.js /usr/share/nginx/html/env.js

# Configuration pour remplacer les variables d'environnement
CMD ["/bin/sh", "-c", "envsubst < /usr/share/nginx/html/env.js > /usr/share/nginx/html/env-config.js && nginx -g 'daemon off;'"]
