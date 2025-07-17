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

### Production Setup

1. **Environment Variables:**

   ```bash
   export SECRET_KEY_BASE="your-production-secret"
   export DATABASE_URL="postgresql://user:pass@host:port/database"
   export ML_RANKING_URL="https://your-ml-service.com/rank"
   export GEMINI_API_KEY="your-gemini-key"
   ```

2. **Database Migration:**

   ```bash
   mix ecto.migrate
   ```

3. **Production Build:**
   ```bash
   MIX_ENV=prod mix release
   ```

### Docker Support

Create a `Dockerfile`:

```dockerfile
FROM elixir:1.18-alpine
WORKDIR /app
COPY mix.exs mix.lock ./
RUN mix deps.get --only prod
COPY . .
RUN MIX_ENV=prod mix release
CMD ["_build/prod/rel/overflow/bin/overflow", "start"]
```

---
