# CapstoneProject2

# HiCampus — Backend Setup Guide

## Prerequisites

Make sure you have the following installed:

- [Docker Desktop](https://www.docker.com/products/docker-desktop/)
- [Python 3.11+](https://www.python.org/downloads/) *(only needed if running locally without Docker)*
---

## 1. Clone the repository GIT

## 2. Set up environment variables

Copy the example env file and fill in the values:

```bash
cp .env.example .env
```

Open `.env` and update the fields:

```env
APP_ENV=development
SECRET_KEY=change-me-in-production

POSTGRES_USER=hicampus
POSTGRES_PASSWORD=hicampus
POSTGRES_HOST=localhost
POSTGRES_PORT=5432
POSTGRES_DB=hicampus

NAVER_MAP_CLIENT_ID=your_ncp_client_id
NAVER_MAP_CLIENT_SECRET=your_ncp_client_secret
```

> **Note:** `POSTGRES_HOST` is automatically overridden to `db` when running via Docker Compose — you do not need to change it.

---

## 3. Add Firebase service account

Obtain the `firebase-service-account.json` file from the team lead and place it in the `backend/` folder:

```
backend/
├── firebase-service-account.json   ← place here
├── .env
├── docker-compose.yml
└── ...
```

> This file is secret and must **never** be committed to Git.

---


This will start two containers:
| Container | Description | Port |
|-----------|-------------|------|
| `api` | FastAPI app | `http://localhost:8000` |
| `db` | PostgreSQL + PostGIS | `localhost:5433` |




## API Endpoints

Auth
GET /api/auth/me
Posts
GET /api/posts
POST /api/posts
PATCH /api/posts/{id}
DELETE /api/posts/{id}
GET /api/posts/{id}/comments
POST /api/posts/{id}/comments

Pins
GET /api/pins
POST /api/pins
GET /api/pins/nearby?lat=&lng=

Users
GET /api/users/{id}
PATCH /api/users/me
GET /api/users?gender=&language=

Authenticated endpoints require a Firebase ID token in the header

## Project Structure

```
backend/
├── app/
│   ├── api/
│   │   ├── deps.py          # Auth dependency (Firebase token verification)
│   │   ├── router.py        # Registers all routers
│   │   └── endpoints/
│   │       ├── auth.py      # /api/auth
│   │       ├── pins.py      # /api/pins
│   │       ├── posts.py     # /api/posts
│   │       ├── users.py     # /api/users
│   │       └── chat.py      # /api/chat
│   ├── core/
│   │   ├── config.py        # App settings (reads from .env)
│   │   └── firebase.py      # Firebase Admin SDK init
│   ├── db/
│   │   ├── base.py          # SQLAlchemy Base
│   │   └── session.py       # DB engine & session
│   ├── models/              # SQLAlchemy models (add here)
│   ├── schemas/             # Pydantic schemas (add here)
│   ├── services/            # Business logic (add here)
│   └── main.py              # FastAPI app entry point
├── .env.example
├── docker-compose.yml
├── Dockerfile
└── requirements.txt
```
