# Overflow - Enhanced Q&A Search Platform

Overflow is an intelligent Q&A search platform that combines Stack Overflow's vast knowledge base with machine learning-powered answer ranking. Built with Elixir/Phoenix, it provides a robust API for searching programming questions and getting AI-enhanced, contextually relevant answers.

## Features

### 🔍 **Intelligent Search**

- Search across Stack Overflow questions with advanced filtering
- Real-time question and answer retrieval
- Contextual search with user preference tracking

### 🤖 **AI-Powered Ranking**

- Machine learning-based answer reranking
- Gemini AI integration for enhanced answer quality
- Pluggable ranking system architecture

### 👥 **User Management**

- Secure user authentication with JWT tokens
- Password hashing with Bcrypt
- User search history tracking

### 🏗️ **Robust Architecture**

- Modular, behavior-driven design
- Configurable external API integrations
- Comprehensive error handling and validation
- Built-in caching for improved performance

## Quick Start

### Prerequisites

- Elixir 1.18+
- PostgreSQL
- Optional: Machine Learning ranking service
- Optional: Gemini API access

### Installation

1. **Clone and install dependencies:**

   ```bash
   git clone <repository-url>
   cd overflow
   mix deps.get
   ```

2. **Set up the database:**

   ```bash
   mix ecto.setup
   ```

3. **Configure environment variables:**

   Create or update `config/dev.exs` with your settings:

   ```elixir
   # Required for production, optional for dev
   config :overflow, secret_key_base: "your-secret-key-base"

   # Authentication
   config :overflow, token_salt: "your-token-salt"

   # ML Ranking Service (optional)
   config :overflow, ml_ranking_url: "http://localhost:8080/rank"
   config :overflow, ml_ranking_timeout: 50000

   # Gemini AI Integration (optional)
   config :overflow, gemini_api_key: "your-gemini-api-key"
   config :overflow, gemini_api_url: "your-gemini-api-url"
   ```

4. **Start the server:**
   ```bash
   mix phx.server
   ```

The application will be available at `http://localhost:4000`.

## 🐳 Docker Setup (Recommended)

For the fastest and most consistent setup, use Docker. This approach handles all dependencies and ensures the same environment across different systems.

### Prerequisites for Docker
- Docker
- Docker Compose
- Make (optional, for convenience commands)

### Quick Start with Docker

1. **Clone the repository:**
   ```bash
   git clone <repository-url>
   cd overflow
   ```

2. **Start development environment:**
   ```bash
   # Using Make (recommended)
   make setup

   # Or using docker-compose directly
   docker-compose -f docker-compose.dev.yml up -d
   ```

3. **Access the application:**
   - 🌐 **Application**: http://localhost:4000
   - 🗄️ **Database**: localhost:5433 (postgres/postgres)

### Docker Commands

#### Development Environment
```bash
# Start development environment
make dev

# View logs
make dev-logs

# Open shell in container
make dev-shell

# Stop development environment
make dev-stop
```

#### Production Environment
```bash
# Build production image
make build

# Start production environment
make run

# View logs
make logs

# Stop production environment
make stop
```

#### Database Operations
```bash
# Set up database (migrations + seeds)
make db-setup

# Run migrations only
make db-migrate

# Reset database
make db-reset
```

#### Testing & Utilities
```bash
# Run tests
make test

# Clean up Docker resources
make clean

# View all available commands
make help
```

### Docker Configuration

#### Environment Files Management
The application uses separate environment files for different environments:

```bash
# Quick setup for development
./setup-env.sh dev

# Quick setup for production (generates secure secrets)
./setup-env.sh prod

# Manual setup
cp .env.example .env.dev    # Development
cp .env.example .env.prod   # Production
```

**Environment Files:**
- `.env.example`: Template with all available variables
- `.env.dev`: Development environment variables
- `.env.prod`: Production environment variables (not committed to git)

**Key Variables:**
- `SECRET_KEY_BASE`: Application secret (auto-generated for production)
- `TOKEN_SALT`: JWT token salt (auto-generated for production)
- `DATABASE_URL`: PostgreSQL connection string
- `GEMINI_API_KEY`: Gemini AI API key (optional)
- `GEMINI_API_URL`: Gemini AI endpoint (optional)
- `ML_RANKING_URL`: External ML service endpoint
- `RERANK_BACKEND`: Ranking backend (`local` or `gemini`)

#### Docker Compose Files
- `docker-compose.yml`: Production configuration (uses `.env.prod`)
- `docker-compose.dev.yml`: Development configuration (uses `.env.dev`)
- `Dockerfile`: Multi-stage production build
- `Dockerfile.dev`: Development build with faster iterations

#### Environment File Security
- Production environment files are automatically excluded from git
- Development files use safe default values
- Production setup script generates secure secrets automatically

### Development Workflow with Docker

1. **Start development environment:**
   ```bash
   make dev
   ```

2. **Make code changes** - they'll be automatically reloaded

3. **Run tests:**
   ```bash
   make test
   ```

4. **View logs:**
   ```bash
   make dev-logs
   ```

5. **Debug in container:**
   ```bash
   make dev-shell
   iex -S mix
   ```

## API Documentation

Overflow provides a comprehensive REST API for searching questions, managing user authentication, and reranking answers. All endpoints return JSON responses.

### Base URL

```
http://localhost:4000/api
```

### Authentication

Most endpoints support optional authentication via JWT tokens. Include the token in the Authorization header:

```
Authorization: Bearer <your-jwt-token>
```

---

### 🔐 Authentication Endpoints

#### Register User

```http
POST /api/signup
```

**Request Body:**

```json
{
  "email": "user@example.com",
  "username": "username",
  "password": "secure-password"
}
```

**Response (201 Created):**

```json
{
  "token": "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9...",
  "user": {
    "id": "user-uuid",
    "email": "user@example.com",
    "username": "username"
  }
}
```

#### Login User

```http
POST /api/login
```

**Request Body:**

```json
{
  "identifier": "user@example.com", // Email
  "password": "secure-password"
}
```

**Response (200 OK):**

```json
{
  "token": "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9...",
  "user": {
    "id": "user-uuid",
    "email": "user@example.com",
    "username": "username"
  }
}
```

---

### 🔍 Search Endpoints

#### Search Questions

```http
POST /api/search
```

**Request Body:**

```json
{
  "q": "How to use async/await in JavaScript"
}
```

**Response (200 OK):**

```json
{
  "questions": [
    {
      "question_id": 1732348,
      "title": "How to use async/await in JavaScript",
      "body": "I'm trying to understand how async/await works...",
      "score": 2339,
      "view_count": 1500000,
      "answer_count": 15,
      "tags": ["javascript", "async-await", "promises"],
      "owner": {
        "user_id": 123456,
        "display_name": "john_doe",
        "reputation": 50000
      },
      "creation_date": "2023-01-15T10:30:00Z",
      "last_activity_date": "2024-07-10T14:20:00Z"
    }
  ]
}
```

#### Get Question Answers

```http
GET /api/search/answers/{question_id}
```

**Response (200 OK):**

```json
{
  "question": {
    "question_id": 1732348,
    "title": "How to use async/await in JavaScript",
    "body": "I'm trying to understand how async/await works...",
    "score": 2339,
    "view_count": 1500000,
    "tags": ["javascript", "async-await", "promises"],
    "owner": {
      "user_id": 123456,
      "display_name": "john_doe",
      "reputation": 50000
    }
  },
  "answers": [
    {
      "answer_id": 1732454,
      "body": "Async/await is syntactic sugar over promises...",
      "score": 8234,
      "is_accepted": true,
      "creation_date": "2023-01-15T11:00:00Z",
      "owner": {
        "user_id": 789012,
        "display_name": "expert_dev",
        "reputation": 100000
      }
    }
  ]
}
```

#### Get Recent Questions (Authenticated)

```http
GET /api/search/recent
Authorization: Bearer <token>
```

**Response (200 OK):**

```json
{
  "questions": [
    {
      "id": "search-uuid",
      "question": "How to handle errors in Elixir",
      "searched_at": "2024-07-17T10:00:00Z"
    }
  ]
}
```

---

### 🤖 AI Ranking Endpoints

#### Rerank Answers

```http
POST /api/rerank
```

**Request Body:**

```json
{
  "question": "How to handle async operations in JavaScript?",
  "answers": [
    {
      "answer_id": 1,
      "body": "Use promises with .then() and .catch()",
      "score": 50
    },
    {
      "answer_id": 2,
      "body": "Use async/await for cleaner syntax",
      "score": 100
    }
  ],
  "preference": "relevance" // or "popularity"
}
```

**Response (200 OK):**

```json
{
  "reranked_answers": [
    {
      "answer_id": 2,
      "body": "Use async/await for cleaner syntax",
      "score": 100,
      "rank": 1,
      "relevance_score": 0.95
    },
    {
      "answer_id": 1,
      "body": "Use promises with .then() and .catch()",
      "score": 50,
      "rank": 2,
      "relevance_score": 0.78
    }
  ]
}
```

#### Rerank Structured Data

```http
POST /api/rerank-structured
```

**Request Body:**
Use the exact response from `/api/search/answers/{question_id}`:

```json
{
  "question": {
    /* question object */
  },
  "answers": [
    /* array of answer objects */
  ]
}
```

**Response (200 OK):**
Returns the same structure with reranked answers and preserved question data.

---

### 📊 Response Status Codes

| Code | Description                              |
| ---- | ---------------------------------------- |
| 200  | OK - Request successful                  |
| 201  | Created - Resource created successfully  |
| 400  | Bad Request - Invalid request data       |
| 401  | Unauthorized - Authentication required   |
| 403  | Forbidden - Insufficient permissions     |
| 404  | Not Found - Resource not found           |
| 422  | Unprocessable Entity - Validation errors |
| 500  | Internal Server Error - Server error     |

### 🔧 Error Response Format

All error responses follow this format:

```json
{
  "error": "Error message description",
  "details": {
    "field": ["validation error message"]
  }
}
```

## Development & Testing

### Running Tests

```bash
# Run all tests
mix test

# Run tests with coverage
mix test --cover

# Run specific test file
mix test test/overflow/search_test.exs
```

### Code Quality Tools

#### Static Analysis with Dialyzer

```bash
# First time setup (creates PLT files)
mix dialyzer --plt

# Run static analysis
mix dialyzer
```

#### Code Linting with Credo

```bash
# Run linting
mix credo

# Run with suggestions
mix credo --strict
```

---

## Architecture

### Core Components

```
lib/
├── overflow/                    # Business Logic Layer
│   ├── accounts/               # User management
│   ├── search/                 # Search functionality
│   └── external/               # External API integrations
│       ├── stack_overflow/     # Stack Overflow API
│       ├── gemini/            # Gemini AI integration
│       └── ranking/           # ML ranking services
└── overflow_web/              # Web Layer
    ├── controllers/           # API controllers
    ├── plugs/                # Authentication middleware
    └── router.ex             # Route definitions
```

### Key Design Patterns

- **Behavior-Driven Architecture**: Pluggable external services via behaviors
- **Context Pattern**: Domain logic organized in contexts (Accounts, Search)
- **Pipeline Architecture**: Request processing through plugs
- **Separation of Concerns**: Clear boundaries between web and business logic

---

## Configuration

### Environment Variables

| Variable             | Description             | Default                      | Required        |
| -------------------- | ----------------------- | ---------------------------- | --------------- |
| `SECRET_KEY_BASE`    | Application secret key  | Generated                    | Production      |
| `TOKEN_SALT`         | JWT token salt          | Default salt                 | No              |
| `ML_RANKING_URL`     | ML ranking service URL  | `http://localhost:8080/rank` | No              |
| `ML_RANKING_TIMEOUT` | ML service timeout (ms) | `50000`                      | No              |
| `GEMINI_API_KEY`     | Gemini AI API key       | -                            | For AI features |
| `GEMINI_API_URL`     | Gemini AI API URL       | -                            | For AI features |
| `DATABASE_URL`       | PostgreSQL connection   | Local DB                     | Production      |

### Configuration Files

- `config/config.exs` - General application config
- `config/dev.exs` - Development environment
- `config/prod.exs` - Production environment
- `config/test.exs` - Test environment
- `config/runtime.exs` - Runtime configuration

---

## Deployment

### 🐳 Docker Deployment (Recommended)

#### Production Deployment with Docker

1. **Prepare environment variables:**
   ```bash
   # Copy and customize environment file
   cp .env.example .env.prod
   
   # Edit .env.prod with production values
   nano .env.prod
   ```

2. **Build and deploy:**
   ```bash
   # Build production image
   docker build -t overflow:latest .
   
   # Start production environment
   docker-compose --env-file .env.prod up -d
   ```

3. **Initialize database:**
   ```bash
   # Run migrations (automatically handled by entrypoint script)
   docker-compose exec app bin/overflow eval "Overflow.Release.migrate"
   ```

#### Cloud Deployment Examples

**AWS ECS/Fargate:**
```yaml
# docker-compose.aws.yml
version: '3.8'
services:
  app:
    image: your-registry/overflow:latest
    environment:
      - DATABASE_URL=${RDS_DATABASE_URL}
      - SECRET_KEY_BASE=${SECRET_KEY_BASE}
      - PHX_HOST=${DOMAIN_NAME}
    ports:
      - "80:4000"
```

**Google Cloud Run:**
```bash
# Build and push
docker build -t gcr.io/your-project/overflow:latest .
docker push gcr.io/your-project/overflow:latest

# Deploy
gcloud run deploy overflow \
  --image gcr.io/your-project/overflow:latest \
  --platform managed \
  --region us-central1 \
  --set-env-vars DATABASE_URL=${DATABASE_URL}
```

**Kubernetes:**
```yaml
# k8s-deployment.yml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: overflow
spec:
  replicas: 3
  selector:
    matchLabels:
      app: overflow
  template:
    metadata:
      labels:
        app: overflow
    spec:
      containers:
      - name: overflow
        image: overflow:latest
        ports:
        - containerPort: 4000
        env:
        - name: DATABASE_URL
          valueFrom:
            secretKeyRef:
              name: overflow-secrets
              key: database-url
        - name: SECRET_KEY_BASE
          valueFrom:
            secretKeyRef:
              name: overflow-secrets
              key: secret-key-base
```

### 🖥️ Traditional Deployment

#### Manual Production Setup

1. **Environment Variables:**
   ```bash
   export SECRET_KEY_BASE="your-production-secret"
   export DATABASE_URL="postgresql://user:pass@host:port/database"
   export ML_RANKING_URL="https://your-ml-service.com/rank"
   export GEMINI_API_KEY="your-gemini-key"
   export PHX_HOST="your-domain.com"
   export PORT=4000
   ```

2. **Database Migration:**
   ```bash
   mix ecto.migrate
   ```

3. **Production Build:**
   ```bash
   MIX_ENV=prod mix release
   ```

4. **Start Application:**
   ```bash
   PHX_SERVER=true _build/prod/rel/overflow/bin/overflow start
   ```

### 🔧 Production Configuration

#### Required Environment Variables
| Variable | Description | Example |
|----------|-------------|---------|
| `SECRET_KEY_BASE` | Application secret key | `openssl rand -base64 64` |
| `DATABASE_URL` | PostgreSQL connection | `postgresql://user:pass@host:5432/db` |
| `PHX_HOST` | Your domain name | `api.yourdomain.com` |
| `PORT` | Application port | `4000` |

#### Optional Environment Variables
| Variable | Description | Default |
|----------|-------------|---------|
| `POOL_SIZE` | Database connection pool | `10` |
| `ML_RANKING_URL` | ML service endpoint | `http://localhost:8080/rank` |
| `GEMINI_API_KEY` | Gemini AI API key | - |
| `RERANK_BACKEND` | Ranking backend (`local`/`gemini`) | `local` |

### 🚀 CI/CD Pipeline Example

#### GitHub Actions
```yaml
# .github/workflows/deploy.yml
name: Deploy to Production

on:
  push:
    branches: [main]

jobs:
  deploy:
    runs-on: ubuntu-latest
    steps:
    - uses: actions/checkout@v3
    
    - name: Build Docker image
      run: docker build -t overflow:${{ github.sha }} .
    
    - name: Deploy to production
      run: |
        docker tag overflow:${{ github.sha }} overflow:latest
        # Deploy using your preferred method
```

### 🔍 Production Monitoring

#### Health Checks
The application provides health check endpoints:
- `GET /health` - Basic health check
- `GET /health/ready` - Readiness probe
- `GET /health/live` - Liveness probe

#### Logging
Production logs are structured JSON for easy parsing:
```bash
# View logs
docker-compose logs -f app

# Filter errors only
docker-compose logs app | grep "level=error"
```

#### Metrics
Access Phoenix LiveDashboard in production (with proper authentication):
- Enable in `config/prod.exs`
- Secure with authentication middleware
- Monitor performance and system metrics

---
