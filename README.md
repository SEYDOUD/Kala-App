# 🧵 Application KALA

## 📋 Prérequis

- [Docker](https://www.docker.com/get-started)
- [Docker Compose](https://docs.docker.com/compose/install/)
- [Git](https://git-scm.com/)
- [Flutter](https://docs.flutter.dev/install)
- [Node JS](https://nodejs.org/en)

## 🚀 Démarrage rapide

### 1. Cloner le projet

```bash
git clone <url-de-votre-repo>
cd Kala-App
```

### 2. Lancer l'application

```bash
docker-compose up --build
```

### 3. Accéder aux services

- **Frontend** : http://localhost:8080
- **Backend** : http://localhost:3000

### Arrêter l'application

```bash
docker-compose down
```

## 📁 Structure du projet

```
Kala-App/
├── backend/              # API Node.js
├── frontend/             # Application Flutter
├── docker-compose.yml
├── .gitignore
└── README.md
```
