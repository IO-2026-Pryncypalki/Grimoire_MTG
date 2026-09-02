#Grimoire MTG

Grimoire is a mobile application for Magic: The Gathering players. It helps users scan and manage cards, build decks, and organize their personal card collection.

The project was developed as a team software engineering project, with a Flutter mobile application and a TypeScript/Node.js backend.

##Features
📷 Card scanning — scan Magic: The Gathering cards and add them to your collection
📚 Collection management — keep track of cards owned by the user
🃏 Deck building — create and manage MTG decks
🔐 User authentication — sign in with Google OAuth 2.0 and use JWT-based authentication
🔄 Access & refresh tokens — short-lived access tokens with refresh-token based session renewal
💾 Persistent storage — user, collection, and application data stored in PostgreSQL
🔎 Card data processing — backend services for working with and synchronizing card data
🧪 Automated tests — backend tests using Jest and Supertest

##Architecture

The project is split into two main parts:

Grimoire_MTG/
├── src/
│   ├── backend/       # TypeScript / Node.js backend
│   └── frontend/      # Flutter mobile application
├── migrations/        # PostgreSQL database migrations
├── tests/             # Backend tests
└── docs/              # Project documentation

##Backend

The backend is implemented in TypeScript using Node.js and Express.

Its structure is divided into separate modules for authentication, collections, decks, sessions, synchronization, repositories, services, routes, and other application concerns.

The backend uses:

Express for the HTTP server and API
Sequelize for database access
PostgreSQL as the database
Passport for authentication strategies
Google OAuth 2.0 for external authentication
JWT for application authentication
node-pg-migrate for database migrations
Jest & Supertest for testing

The repository contains dedicated modules for authentication, collection management, decks, sessions, synchronization, repositories, services, and API routes.

##Authentication

Grimoire uses Google OAuth 2.0 together with JWT-based authentication.

The authentication flow uses separate access and refresh tokens. Access tokens are used to authenticate requests, while refresh tokens allow the application to issue new access tokens without requiring the user to authenticate with Google again.

The backend also supports extracting the access token from an HTTP-only cookie or a Bearer authorization header.

##Frontend

The mobile client is built with Flutter and is located in src/frontend/grimoire_mtg.

The Flutter project includes platform-specific targets for Android, iOS, Web, Linux, macOS, and Windows, together with integration and unit-test directories.

##Database

The backend uses PostgreSQL for persistent application data.

Database changes are managed through migration files using node-pg-migrate. The project provides scripts for creating, applying, and reverting migrations.

##Testing

The backend uses Jest with ts-jest for TypeScript tests and Supertest for HTTP-level testing.

Available scripts include:

npm test
npm run test:coverage

The repository also contains a dedicated tests directory and Jest configuration.

##Running the Backend

Install dependencies:

npm install

Create the required environment configuration and database settings, then run the migrations:

npm run migrate:up

Start the backend in development mode:

npm run dev

Or start it normally:

npm start

The exact environment variables required by the application should be configured according to the project's backend configuration before starting the server. The repository provides dedicated scripts for development, production-style startup, and database migrations.

##Technologies

Mobile

Flutter

##Backend

TypeScript
Node.js
Express

##Database

PostgreSQL
Sequelize
node-pg-migrate

##Authentication

Passport
Google OAuth 2.0
JWT

##Testing

Jest
Supertest

##Development

Git
npm
Project

Grimoire MTG was developed as a collaborative academic software engineering project.

The repository contains the complete application, including the mobile client, backend services, database migrations, tests, and supporting documentation.
