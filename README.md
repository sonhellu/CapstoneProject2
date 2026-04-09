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

## 4. Run with Docker (recommended)

```bash
docker compose up --build
```

This will start two containers:
| Container | Description | Port |
|-----------|-------------|------|
| `api` | FastAPI app | `http://localhost:8000` |
| `db` | PostgreSQL + PostGIS | `localhost:5433` |

To run in the background:

```bash
docker compose up --build -d
```

To stop:

```bash
docker compose down
```

---

## 5. Verify it's working

Open your browser or use curl:

```bash
curl http://localhost:8000/docs
```

You should see the Swagger UI with all available API endpoints.

---

## 6. Connect to the database (optional)

Use [TablePlus](https://tableplus.com/) or any PostgreSQL client:

| Field | Value |
|-------|-------|
| Host | `127.0.0.1` |
| Port | `5433` |
| User | `hicampus` |
| Password | `hicampus` |
| Database | `hicampus` |

---

## API Endpoints

| Method | Endpoint | Description | Auth required |
|--------|----------|-------------|---------------|
| `GET` | `/api/auth/me` | Get current user info | Yes |
| `GET` | `/api/pins/` | List pins | — |
| `GET` | `/api/posts/` | List posts | — |
| `GET` | `/api/users/` | List users | — |
| `GET` | `/api/chat/` | Chat | — |

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
