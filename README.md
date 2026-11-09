# esim_provisioning

[![pub package](https://img.shields.io/pub/v/esim_provisioning.svg?logo=dart)](https://pub.dev/packages/esim_provisioning)
[![likes](https://img.shields.io/pub/likes/esim_provisioning)](https://pub.dev/packages/esim_provisioning)
[![pub points](https://img.shields.io/pub/points/esim_provisioning)](https://pub.dev/packages/esim_provisioning/score)
[![license](https://img.shields.io/github/license/Bahadir10/esim_provisioning)](https://github.com/Bahadir10/esim_provisioning/blob/main/LICENSE)
[![Platforms](https://img.shields.io/badge/platforms-iOS%20%7C%20Android%20%7C%20Windows%20%7C%20macOS%20%7C%20Web-blue)](https://pub.dev/packages/esim_provisioning)

Production-grade **eSIM (eUICC) profile provisioning, hardware capability detection, and GSMA SGP.22 LPA activation code parser** for Flutter (`iOS`, `Android`, `Windows`, `macOS`, and `Web`).

Designed for travel apps, telecom operators, MVNOs, and enterprise IoT devices needing reliable eSIM profile installation without getting blocked by platform entitlement barriers.

---

## 🌟 Key Highlights & Why `esim_provisioning`?

| Challenge in Standard eSIM SDKs | How `esim_provisioning` Solves It |
| :--- | :--- |
| **Apple Carrier Entitlement Lockout** | Direct silent installation on iOS requires private carrier entitlement (`com.apple.developer.networking.carrier-proposals`). Our engine supports direct installation when entitled, and **automatically falls back to Apple's official iOS 17.4+ eSIM Universal Link** (`https://esimsetup.apple.com/esim_qrcode_provisioning?carddata=...`) so any standard App Store app can prompt the native cellular setup sheet. |
| **Android Privileged vs Standard Apps** | Seamlessly uses `EuiccManager.downloadSubscription` for carrier-privileged apps and launches `ACTION_PROVISION_EMBEDDED_SUBSCRIPTION` system setup wizard dialogs for standard Play Store apps. |
| **GSMA SGP.22 Standard Compliance** | Fully parses and validates activation code strings (`LPA:1$<SMDP_Address>$<Matching_ID>[$<Confirmation_Code>][$<IMEI>]`), sanitizing user inputs and preventing runtime crashes. |
| **Normalized Telecom Error Codes** | Maps heterogeneous iOS CoreTelephony results and Android detailed error codes (`ERROR_CARRIER_LOCKED`, `ERROR_INVALID_ACTIVATION_CODE`, `ERROR_INSUFFICIENT_MEMORY`, `ERROR_TIME_OUT`) into unified, type-safe Dart enums. |
| **Integrated Mock SM-DP+ Test Server** | Bundles a lightweight Go SM-DP+ server in `tool/go_esim_harness` that dynamically orders profiles, generates valid LPA strings, and verifies download callbacks locally. |

---

## 🏗️ Architecture & Provisioning Flow

```text
    User / Backend provides Activation Code
                       │
                       ▼
      [ LpaActivationCode.parse(rawLpa) ]
         (Validates GSMA SGP.22 Syntax)
                       │
                       ▼
      [ EsimProvisioning.instance.getCapabilities() ]
         (Verifies eUICC hardware & carrier privileges)
                       │
           ┌───────────┴───────────┐
           ▼                       ▼
         [ iOS ]               [ Android ]
           │                       │
     Carrier Entitled?        Carrier Privileged?
     ├─ Yes ──► addPlan()     ├─ Yes ──► downloadSubscription()
     └─ No  ──► Universal     └─ No  ──► ACTION_PROVISION_...
                Link Sheet               System Dialog
           │                       │
           └───────────┬───────────┘
                       │
                       ▼
        Unified EsimInstallResult (status & errorCode)
```

---

## 📱 Platform Setup Guide

### 1. iOS Setup

In `ios/Runner/Info.plist`:

```xml
<!-- Optional: Description if querying carrier data -->
<key>NSTelephonyUsageDescription</key>
<string>$(PRODUCT_NAME) uses telephony capabilities to configure eSIM cellular plans.</string>
```

> **Note on Carrier Entitlements**: If your app is an authorized carrier application with Apple's `com.apple.developer.networking.carrier-proposals` entitlement, the plugin automatically performs silent in-app provisioning via `CTCellularPlanProvisioning`. If your app is a standard App Store app (e.g. travel/roaming), the plugin seamlessly triggers Apple's native cellular setup sheet via Universal Link.

---

### 2. Android Setup

In `android/app/src/main/AndroidManifest.xml`:

```xml
<manifest xmlns:android="http://schemas.android.com/apk/res/android">
    <!-- Optional: Allows reading telephony network states -->
    <uses-permission android:name="android.permission.READ_PHONE_STATE" />
</manifest>
```

---

## 🚀 Quick Start & Code Examples

### 1. Check Device eSIM Capabilities

Always verify that the user's device contains an eUICC chip before attempting to download:

```dart
import 'package:esim_provisioning/esim_provisioning.dart';

Future<void> checkEsimSupport() async {
  final caps = await EsimProvisioning.instance.getCapabilities();

  print('eSIM Hardware Supported: ${caps.isSupported}');
  print('eUICC Subsystem Enabled: ${caps.isEnabled}');
  print('Device EID: ${caps.eid ?? "Hidden by OS privacy"}');
  print('Carrier Privileges: ${caps.hasCarrierPrivileges}');
  print('Can download silently: ${caps.supportsDirectDownload}');
}
```

---

### 2. Parse & Validate GSMA LPA Strings

```dart
// 1. Parse standard GSMA SGP.22 activation string
final lpa = LpaActivationCode.parse(
  'LPA:1\$smdp.example.com\$1234-ABCD-5678-EFGH\$CONF1234',
);

print('SM-DP+ Host: ${lpa.smdpAddress}'); // smdp.example.com
print('Matching ID: ${lpa.matchingId}');   // 1234-ABCD-5678-EFGH
print('Confirmation Code: ${lpa.confirmationCode}'); // CONF1234

// 2. Or use tryParse to safely handle user QR code inputs
final userLpa = LpaActivationCode.tryParse(scannedQrCode);
if (userLpa == null) {
  print('Invalid QR code format. Please scan a valid eSIM voucher.');
}
```

---

### 3. Install an eSIM Profile

```dart
// Pass either an LpaActivationCode instance or a raw string
final result = await EsimProvisioning.instance.install(
  rawLpaString: 'LPA:1\$smdp.example.com\$1234-ABCD-5678-EFGH',
  switchAfterDownload: true, // Switch to new plan upon completion
);

if (result.isSuccess) {
  print('eSIM profile provisioned successfully: ${result.message}');
} else if (result.isCanceled) {
  print('User canceled eSIM installation.');
} else {
  print('Installation failed (${result.errorCode.name}): ${result.message}');
  // e.g. EsimErrorCode.carrierLocked, EsimErrorCode.insufficientMemory
}
```

---

### 4. Open System SIM & Cellular Settings

Direct the user to the native operating system's cellular/mobile data management screen:

```dart
await EsimProvisioning.instance.openCellularSettings();
```

---

## 🛠️ Local Testing with Go SM-DP+ Harness (`tool/go_esim_harness`)

Included with this repository is a lightweight Go server simulating a GSMA SM-DP+ backend for zero-touch local testing:

```bash
# Navigate to the harness directory
cd tool/go_esim_harness

# Start the mock SM-DP+ server (listens on http://127.0.0.1:8095)
go run ./cmd/server
```

### Supported Endpoints:
- `POST /api/esim/order` — Dynamically generates a valid GSMA LPA profile string (`LPA:1$127.0.0.1:8095$ORD-...`).
- `GET /api/esim/profiles/:matchingId` — Inspects profile download and activation state.
- `POST /api/esim/simulate-download` — Marks profile as downloaded.
- `POST /api/esim/simulate-error` — Injects error conditions (e.g. `INSUFFICIENT_MEMORY`, `CARRIER_LOCKED`).

---

## 🔗 Flutter Telecom Suite

Pair this package with our other production-grade telecom libraries:
- [`voip_call_engine`](https://pub.dev/packages/voip_call_engine) — Deterministic VoIP Call Lifecycle, CallKit, ConnectionService, and WebRTC Audio Engine.

---

## 📄 License

This project is licensed under the MIT License — see the [LICENSE](LICENSE) file for details.
