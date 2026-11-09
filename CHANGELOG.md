## 0.1.0

* Initial release of `esim_provisioning`.
* GSMA SGP.22 LPA activation code parser, validator, and Apple Universal Link (`toAppleUniversalLink()`) generator.
* Android `EuiccManager` integration supporting both direct carrier-privileged downloads and native system provisioning dialogs.
* iOS `CoreTelephony` (`CTCellularPlanProvisioning`) integration with automatic fallback to Apple Universal Link eSIM setup sheets.
* Desktop (Windows, macOS) and Web compatibility for capability detection, LPA validation, and cellular settings.
* Integrated Go SM-DP+ test harness (`tool/go_esim_harness`) for zero-touch local E2E simulation.
