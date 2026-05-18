# TravelEasy — Application Agence de Voyage IA

> Application mobile & web de planification de voyage propulsée par l'IA.

![Flutter](https://img.shields.io/badge/Flutter-3.22-blue?logo=flutter)
![FastAPI](https://img.shields.io/badge/FastAPI-0.110-green?logo=fastapi)
![PostgreSQL](https://img.shields.io/badge/PostgreSQL-16-blue?logo=postgresql)
![Docker](https://img.shields.io/badge/Docker-Compose-blue?logo=docker)
![CI/CD](https://img.shields.io/badge/CI%2FCD-GitHub%20Actions-black?logo=github-actions)

---

## Sommaire

- [Présentation](#présentation)
- [Architecture](#architecture)
- [Stack technique](#stack-technique)
- [Démarrage rapide](#démarrage-rapide)
- [Variables d'environnement](#variables-denvironnement)
- [CI/CD](#cicd)
- [Structure du projet](#structure-du-projet)
- [Roadmap](#roadmap)

---

## Présentation

TravelEasy permet à un utilisateur de renseigner sa **ville de départ**, sa **destination**, son **budget**, ses **dates** et ses **préférences** de voyage.

Le moteur IA analyse les offres disponibles (trains, vols, hôtels, activités) et propose des itinéraires optimisés. La réservation et le paiement se font directement dans l'application.

### Fonctionnalités MVP

- Authentification (Firebase Auth + JWT)
- Recherche train + hôtel selon budget
- Moteur de recommandation IA (OpenAI)
- Réservation et paiement sécurisé (Stripe)
- Historique des voyages
- Notifications push en temps réel
- Assistant IA conversationnel

---

## Architecture

```
┌────────────────────────────────────────────────────────┐
│                   CLIENT                               │
│  Flutter (iOS / Android / Web)                         │
└────────────────────┬───────────────────────────────────┘
                     │ HTTPS / REST + WebSocket
┌────────────────────▼───────────────────────────────────┐
│                  BACKEND (FastAPI)                     │
│  Auth │ Trips │ Bookings │ Payments │ AI │ Notifs       │
└──┬──────────┬─────────────┬──────────────┬─────────────┘
   │          │             │              │
  PG       Redis         Stripe        OpenAI / Firebase
```

---

## Stack technique

| Couche | Technologie |
|--------|-------------|
| Mobile + Web | Flutter 3.22 |
| Backend | FastAPI (Python 3.12) |
| Base de données | PostgreSQL 16 |
| Cache | Redis 7 |
| Auth | Firebase Auth + JWT |
| Paiement | Stripe |
| IA | OpenAI API (GPT-4) |
| Stockage | AWS S3 / Firebase Storage |
| Infra | Docker + Docker Compose |
| CI/CD | GitHub Actions |

---

## Démarrage rapide

### Prérequis

- Docker >= 24
- Docker Compose >= 2.20
- Flutter SDK >= 3.22 (pour le dev frontend local)
- Python >= 3.12 (pour le dev backend local)

### Lancer l'environnement complet

```bash
# 1. Cloner le dépôt
git clone https://github.com/samibouyat-wq/TravelEasy.git
cd TravelEasy

# 2. Copier et configurer les variables d'environnement
cp .env.example .env
# Éditer .env avec vos clés API

# 3. Démarrer tous les services
make up

# 4. Appliquer les migrations de base de données
make migrate

# 5. Accéder à l'application
# API docs  : http://localhost:8000/docs
# Frontend  : http://localhost:3000
# PgAdmin   : http://localhost:5050
```

### Commandes utiles

```bash
make up          # Démarrer tous les services
make down        # Arrêter tous les services
make logs        # Voir les logs
make migrate     # Appliquer les migrations Alembic
make test        # Lancer les tests backend
make lint        # Linter le code backend
make build       # Builder les images Docker
```

---

## Variables d'environnement

Copier `.env.example` vers `.env` et renseigner :

```
DATABASE_URL, REDIS_URL, SECRET_KEY,
FIREBASE_*, STRIPE_*, OPENAI_API_KEY,
SNCF_API_KEY, AMADEUS_*, BOOKING_*...
```

Voir `.env.example` pour la liste complète.

---

## CI/CD

Deux workflows GitHub Actions :

| Workflow | Déclencheur | Actions |
|----------|------------|--------|
| `ci.yml` | Push / PR sur toutes branches | Lint, Tests, Build Docker |
| `cd.yml` | Push sur `main` | Build + Push GHCR + Deploy |

---

## Structure du projet

```
traveleasy/
├── .github/
│   └── workflows/
│       ├── ci.yml
│       └── cd.yml
├── backend/
│   ├── app/
│   │   ├── core/          # Config, DB, Sécurité
│   │   ├── models/        # Modèles SQLAlchemy
│   │   ├── schemas/       # Schémas Pydantic
│   │   ├── routes/        # Endpoints API
│   │   └── services/      # Logique métier
│   ├── tests/
│   ├── Dockerfile
│   └── requirements.txt
├── frontend/
│   ├── lib/
│   │   ├── core/          # Thème, constantes, routing
│   │   ├── features/      # Auth, Search, Booking, AI
│   │   └── services/      # API, Auth, Notification
│   ├── web/
│   ├── Dockerfile
│   └── pubspec.yaml
├── nginx/
│   ├── nginx.conf
│   └── Dockerfile
├── docker-compose.yml
├── docker-compose.prod.yml
├── Makefile
└── .env.example
```

---

## Roadmap

- [x] **V1** — MVP : recherche train + hôtel, paiement Stripe, notifications, assistant IA
- [ ] **V2** — Ajout vols + activités
- [ ] **V3** — Réservation automatique IA
- [ ] **V4** — Assistant vocal

---

## Licence

MIT © 2026 TravelEasy
