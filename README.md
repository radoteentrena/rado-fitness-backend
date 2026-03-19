# Rado Fitness

export $(grep -v '^#' .env | xargs) && kamal deploy

This README would normally document whatever steps are necessary to get the
application up and running.

Things you may want to cover:

* Ruby version

* System dependencies

* Configuration

* Database creation

* Database initialization

* How to run the test suite

* Services (job queues, cache servers, search engines, etc.)

* Deployment instructions

* ...

## AI Coach Feature

This project includes an AI Coach feature that uses RAG (Retrieval-Augmented Generation) to create personalized training programs.

### Requirements

- **PostgreSQL with pgvector extension**: The database must support vector operations.
- **OpenAI API Key**: Required for generating embeddings and chat completions.

### Architecture

- **Books & Chunks**: PDF books are ingested and split into chunks with vector embeddings.
- **AI Conversation**: Handles the chat interaction with the user.
- **AI Coach Service**: Orchestrates the program generation.

## React Native API

The Rails backend serves as an API for the accompanying React Native app.
- **Namespace:** `/api/v1`
- **Authentication:** Stateless token-based (`Authorization: Bearer <user_auth_token>`).
- **Endpoints:** The API enables mobile clients to read schedules/exercises, log workouts, save daily metrics, and upload progress photos.
