# How to run:

## 1. Download Flutter

Follow the instructions on https://docs.flutter.dev/install. Simplest way is to use VSCode.

---

## 2. Download Android Studio or prepare a physical device.

Download from https://developer.android.com/studio and setup an emulator or enable USB Debugging on your physical device.

---

## 3. Download all the dependencies.

Run:

```bash
flutter pub get
```

---

## 4. Check devices.

Run:

```bash
flutter devices
```

to see all available devices (you should see you emulator or phone).

---

## 5. Select the device.

In VSCode you can select the target device in the bottom right corner. If you aren't using VSCode you can add ``` -d DEVICE_ID ``` to your run command.

---

## 6. Run the project.

Run:

```bash
flutter run
```

it may take a while to start.

## 6. Backend URL (API)

The app talks to the backend at `http://localhost:3000` by default. Override with `--dart-define`:

```bash
# Android emulator → host machine
flutter run --dart-define=API_BASE_URL=http://10.0.2.2:3000

# Physical device on same LAN (replace with your machine IP)
flutter run --dart-define=API_BASE_URL=http://192.168.1.100:3000

# Flutter Web (backend must allow CORS for your web origin)
flutter run -d chrome --dart-define=API_BASE_URL=http://localhost:3000
```

Set backend `FE_BASE_URL` to your **Flutter Web origin** (the URL shown when you run `flutter run -d chrome`, e.g. `http://localhost:54321`). Do **not** set it to the backend URL — after Google login the browser is redirected there and the Flutter app loads your profile UI (not raw JSON).

Example `.env`:

```
BE_BASE_URL=http://localhost:3000
FE_BASE_URL=http://localhost:54321
```

Restart the backend after changing `FE_BASE_URL`.

## 7. Enjoy :\)