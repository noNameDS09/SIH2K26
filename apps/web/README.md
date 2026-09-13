# SIH2K26 — Web

The Next.js web application for **KalaSetu**, the SIH2K26 project.

KalaSetu is a voice-first digital cataloging platform designed to help artisans create, manage, and publish craft product listings. The web application provides the public-facing catalog and product verification experience.

## Architecture

The application uses Next.js with the App Router and is organized into the following initial layers:

```text
src/
├── app/          # Next.js routes and pages
├── components/   # Reusable UI components
│   └── ui/
├── api/          # API communication
├── lib/          # Shared utilities and application logic
└── types/        # TypeScript types and contracts
```

## Development

### Requirements

* Node.js 26+
* npm

### Install dependencies

```bash
npm install
```

### Run the development server

```bash
npm run dev
```

Open `http://localhost:3000` in your browser.

### Build for production

```bash
npm run build
```

### Start the production server

```bash
npm run start
```

### Lint

```bash
npm run lint
```

## Application Scope

The web application will provide the public-facing side of the KalaSetu workflow:

```text
Published Listing
       ↓
   Web Catalog
       ↓
    /market
       ↓
 Product Details
       ↓
    /v/[id]
```

The web application consumes data published by the SIH2K26 backend and does not act as a marketplace with cart, checkout, or payment functionality.

## Project Structure

The web application is part of the SIH2K26 monorepo:

```text
SIH2K26/
├── apps/
│   ├── api/       # FastAPI backend
│   ├── mobile/    # Flutter mobile application
│   └── web/       # Next.js web application
│
├── packages/      # Shared packages and contracts
├── seed/          # Seed data
└── docs/           # Project documentation
```

## Status

The Next.js application is currently scaffolded with the initial project structure. KalaSetu web features will be implemented incrementally.

## Documentation

See [Docs](../../docs/) for project-level architecture, feature specifications, API contracts, and implementation guidelines are maintained in the root SIH2K26 repository.

For Next.js documentation, refer to the official Next.js documentation.
