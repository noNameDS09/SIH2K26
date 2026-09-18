# Local Development Guide

This guide provides instructions for setting up and running the KalaSetu project natively on your local machine without using Docker.

## 1. Backend API (`apps/api`)

The backend is built with FastAPI (Python 3.12+).

### Prerequisites
- Python 3.12 or newer installed.
- (Optional but recommended) `uv` or `pip` for package management.

### Setup Instructions
1. Navigate to the API directory:
   ```bash
   cd apps/api
   ```
2. Create and activate a virtual environment:
   #### For macOS / Linux (RHEL, Fedora, Debian, Ubuntu, Arch, etc.)
   ```bash
    python3 -m venv .venv
    source .venv/bin/activate
   ```

   #### Windows Powershell
   ```powershell
   python -m venv .venv
   .venv\Scripts\Activate.ps1
   ```

   #### Windows CMD
   ```cmd
   python -m venv .venv
   .venv\Scripts\activate.bat
   ```

3. Install dependencies:
   ```bash
   pip install -e ".[dev,voice,studio]"
   ```
4. Setup environment variables:
   - Ensure your `.env` file is present in `apps/api`.
   - Ensure your `firebase-adminsdk.json` is correctly configured in your `.env`.

### Running the Server
```bash
uvicorn kalasetu_api.main:app --reload --host 0.0.0.0 --port 8000
```
The API will be available at `http://localhost:8000`. You can view the interactive documentation at `http://localhost:8000/docs`.

---

## 2. Web Frontend (`apps/web`)

The web frontend is built using Next.js and React.

### Prerequisites
- Node.js (v20 or newer).
- `npm` (usually comes with Node.js).

### Setup Instructions
1. Navigate to the web directory:
   ```bash
   cd apps/web
   ```
2. Install dependencies:
   ```bash
   npm install
   ```

### Running the Development Server
```bash
npm run dev
```
The web application will be accessible at `http://localhost:3000`.

---

## 3. Mobile Application (`apps/mobile`)

The mobile application is developed using Flutter and supports Android emulators, physical Android devices, and iOS simulators/devices where applicable.

### Prerequisites

* Flutter SDK **3.24 or newer**
* Dart SDK compatible with the installed Flutter version
* Android SDK and Android Platform Tools for Android development
* Android Emulator **or** a physical Android device with USB debugging enabled
* Xcode and iOS Simulator for iOS development on macOS
* A running instance of the backend API

Verify the Flutter installation:

```bash
flutter doctor
```

Resolve any required Android or iOS toolchain issues reported by `flutter doctor` before proceeding.

### Setup

1. Navigate to the mobile application directory:

```bash
cd apps/mobile
```

2. Install Flutter dependencies:

```bash
flutter pub get
```

3. Configure the backend API URL.

Open:

```text
lib/services/api_service.dart
```

Set `baseUrl` to the address of the running backend.

The correct URL depends on how the application is being tested.

| Environment             | API URL                        |
| ----------------------- | ------------------------------ |
| Physical Android device | `http://<YOUR-PC-LAN-IP>:8000` |
| Android Emulator        | `http://10.0.2.2:8000`         |
| iOS Simulator           | `http://localhost:8000`        |
| Physical iOS device     | `http://<YOUR-PC-LAN-IP>:8000` |

For example:

```text
http://192.168.1.100:8000
```

> **Important:** When using a physical device, the computer running the backend and the mobile device must normally be connected to the same local network. Replace `<YOUR-PC-LAN-IP>` with the local IP address of the machine running the backend.

### Running on Android

First, check whether Flutter can detect a connected device or emulator:

```bash
flutter devices
```

You should see the target device listed.

#### Option A — Android Emulator

If you already have an Android Virtual Device (AVD) configured, start the emulator through Android Studio's Device Manager or the Android Emulator command-line tools.

Then verify:

```bash
flutter devices
```

Run the application:

```bash
flutter run
```

If multiple devices are available, specify the target:

```bash
flutter run -d <device-id>
```

For the standard Android Emulator, the backend should generally be configured as:

```text
http://10.0.2.2:8000
```

`10.0.2.2` allows the Android Emulator to access the host machine's `localhost`.

#### Option B — Physical Android Device via USB

1. Enable **Developer Options** on the Android device.

   * Open **Settings → About phone**.
   * Locate **Build number**.
   * Tap **Build number** approximately seven times until Developer Options are enabled.
   * The exact menu location may vary by device manufacturer and Android version.

2. Open **Developer Options**.

3. Enable:

```text
USB debugging
```

4. Connect the device to the development computer using a USB cable.

5. If the device displays an **Allow USB debugging?** prompt, approve the computer's RSA key.

6. Verify that ADB detects the device:

```bash
adb devices
```

The device should appear with a status similar to:

```text
XXXXXXXX    device
```

7. Verify that Flutter detects the device:

```bash
flutter devices
```

8. Run the application:

```bash
flutter run
```

For a physical Android device, do **not** use `localhost` for the backend API. Use the development computer's LAN IP address instead:

```text
http://<YOUR-PC-LAN-IP>:8000
```

### Running on iOS

> iOS development and device deployment require macOS with Xcode installed.

For the iOS Simulator:

1. Install Xcode from the Mac App Store.
2. Install the required iOS Simulator runtime.
3. Start the desired simulator.
4. Verify that Flutter detects it:

```bash
flutter devices
```

5. Run:

```bash
flutter run
```

For the iOS Simulator, the backend can generally be accessed using:

```text
http://localhost:8000
```

For a physical iPhone/iPad:

1. Connect the device to the Mac.
2. Trust the development computer when prompted.
3. Configure the device for development through Xcode.
4. Verify that Flutter detects the device:

```bash
flutter devices
```

5. Run:

```bash
flutter run -d <device-id>
```

For a physical iOS device, use the development computer's LAN IP for the backend:

```text
http://<YOUR-MAC-LAN-IP>:8000
```

### Finding the Development Computer's Local IP

If a physical device is being used, determine the local IP address of the computer running the backend.

**Linux / macOS:**

```bash
ifconfig
```

or:

```bash
ip addr
```

Look for the active network interface and its local IPv4 address, for example:

```text
192.168.1.100
```

**Windows:**

```powershell
ipconfig
```

Look for the **IPv4 Address** of the active network adapter.

Then configure:

```text
http://192.168.1.100:8000
```

### Building the Android APK

For a debug APK:

```bash
flutter build apk --debug
```

The generated APK will be located at:

```text
apps/mobile/build/app/outputs/flutter-apk/app-debug.apk
```

For a release APK:

```bash
flutter build apk --release
```

The generated APK will be located at:

```text
apps/mobile/build/app/outputs/flutter-apk/app-release.apk
```

### Troubleshooting

**Device is not detected**

Run:

```bash
flutter devices
```

For Android devices, also run:

```bash
adb devices
```

If the device is listed as `unauthorized`, unlock the phone and accept the USB debugging authorization prompt.

**Android Emulator cannot connect to the backend**

Do not use:

```text
http://localhost:8000
```

Use:

```text
http://10.0.2.2:8000
```

when using the standard Android Emulator.

**Physical device cannot connect to the backend**

Check that:

1. The development computer and mobile device are connected to the same network.
2. The backend is running and listening on the appropriate network interface.
3. The configured API URL uses the development computer's LAN IP.
4. Port `8000` is accessible through the computer's firewall/network configuration.

**Flutter reports Android toolchain issues**

Run:

```bash
flutter doctor
```

Follow the reported Android SDK, platform, license, or toolchain requirements.

**List available Flutter devices**

```bash
flutter devices
```

**List available Android emulators**

```bash
flutter emulators
```

### Recommended Setup for SIH Demonstration

For a reliable demonstration, the recommended setup is:

```text
Development Computer
        │
        ├── Backend API :8000
        │
        └── Flutter Application
                │
                ├── Android Emulator
                │
                └── Physical Android Device
```

For a physical-device demonstration, connect the computer and device to the same network and configure the mobile application to use the computer's LAN IP address.

Before the demonstration, verify the complete flow using:

```bash
flutter doctor
flutter devices
adb devices
```

and confirm that the backend is reachable from the selected mobile device.
