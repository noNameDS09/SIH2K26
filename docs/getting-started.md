# Getting Started with KalaSetu

Welcome to the KalaSetu project repository. This document provides a high-level overview of the project structure and how to begin development.

## Project Structure

This is a monorepo containing three distinct applications under the `apps/` directory:

1. **`apps/api` (Backend)**
   - **Framework:** FastAPI (Python)
   - **Description:** The core backend server handling AI cataloging, image enhancement, speech-to-text, TTS, and database operations via Firebase Firestore.

2. **`apps/web` (Frontend Web Application)**
   - **Framework:** Next.js (React)
   - **Description:** The consumer-facing web application and dashboard interface.

3. **`apps/mobile` (Mobile Application)**
   - **Framework:** Flutter (Dart)
   - **Description:** The mobile application designed for artisans to capture product photos, interact with the AI assistant via voice, and manage their listings.

## Prerequisites


- **Flutter SDK:** Required if you intend to actively develop or debug the mobile application.
- **Node.js (v20+):** Required for local web application development.
- **Python (3.12+):** Required for local API development.

## Setting Up the Environment

1. **API Keys and Secrets:**
   - Create a `.env` file in the root directory and ensure all necessary API keys are populated.
   - Place your Firebase Admin SDK service account JSON file at `secrets/firebase-adminsdk.json`.

2. **Starting the Services:**
   - See [Development Guide](./development-guide.md) for instructions on how to start the Web,API service and build the mobile app.

3. **Starting the Services using docker:**
   - See [Docker Deployment Guide](./docker.md) for instructions on how to start the Web and API services using Docker.

## Technical Architecture
Please refer to the `Technical Architecture.png` file in this folder for a visual representation of how the different components of the system communicate with each other.
