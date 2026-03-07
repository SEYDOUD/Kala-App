# Stage 1: Build
FROM ghcr.io/cirruslabs/flutter:stable AS build

WORKDIR /app

# Copier les fichiers de dépendances
COPY pubspec.yaml pubspec.lock* ./

# Activer web et installer les dépendances
RUN flutter config --enable-web && \
    flutter pub get

# Copier le reste du code
COPY . .

# URL backend injectee au build Flutter web
ARG API_BASE_URL=http://localhost:3000

# Builder en mode release
RUN flutter build web --release --dart-define=API_BASE_URL=${API_BASE_URL}

# Stage 2: Servir avec Nginx
FROM nginx:alpine

# Copier les fichiers buildés
COPY --from=build /app/build/web /usr/share/nginx/html

# Configuration Nginx simple
COPY <<EOF /etc/nginx/conf.d/default.conf
server {
    listen 80;
    server_name _;
    
    location / {
        root /usr/share/nginx/html;
        index index.html;
        try_files \$uri \$uri/ /index.html;
    }
}
EOF

EXPOSE 80

CMD ["nginx", "-g", "daemon off;"]
