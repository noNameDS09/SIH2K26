# Docker Deployment Guide
> **Note:** For the best development experience, it is currently recommended to set up and run the project without Docker. The existing Docker configuration may not function as expected in the current version. We are actively working to resolve these issues and will update the Docker configuration as soon as possible.

This guide explains how to build and run the KalaSetu services using Docker.

## Running the Web and API (Backend + Frontend)

The fastest way to spin up both the **Next.js Web Application** and the **FastAPI Backend** is by using `docker-compose`.

1. **Setup your environment:** Ensure you have `.env` and `secrets/firebase-adminsdk.json` configured in the root directory.
2. **Start the services:**
   ```bash
   docker-compose up --build -d
   ```
3. **Access the applications:**
   - **Web UI:** http://localhost:3000
   - **API Docs (Swagger UI):** http://localhost:8000/docs

To stop the services, run:
```bash
docker-compose down
```

## Mobile Application (Flutter)

The mobile application is located in `apps/mobile`. While we do not run the mobile application as a server in Docker Compose, you can development server or build the mobile app after installing the Flutter SDK on your host machine.

### Building the APK via Docker

Run the following command from the root directory of the project:

```bash
# from root directory
cd apps/mobile
flutter pub get
# for quick build use the debug application
flutter build apk --debug
# for optimised build use the --release flag
flutter build apk --release
```

Once finished, the compiled APK will be available on your host machine at:
`apps/mobile/build/app/outputs/flutter-apk/app-debug.apk`
OR
`apps/mobile/build/app/outputs/flutter-apk/app-release.apk`
