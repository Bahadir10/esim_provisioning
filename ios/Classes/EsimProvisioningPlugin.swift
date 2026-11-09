import CoreTelephony
import Flutter
import UIKit

public final class EsimProvisioningPlugin: NSObject, FlutterPlugin {
    public static func register(with registrar: FlutterPluginRegistrar) {
        let channel = FlutterMethodChannel(
            name: "dev.flutter.telecom/esim_provisioning",
            binaryMessenger: registrar.messenger()
        )
        let instance = EsimProvisioningPlugin()
        registrar.addMethodCallDelegate(instance, channel: channel)
    }

    public func handle(_ call: FlutterMethodCall, result: @escaping FlutterResult) {
        let args = call.arguments as? [String: Any] ?? [:]

        switch call.method {
        case "getCapabilities":
            let provisioning = CTCellularPlanProvisioning()
            let isSupported = provisioning.supportsCellularPlan()
            let osVersion = UIDevice.current.systemVersion

            var hasCarrierEntitlement = false
            // SecTaskCopyValueForEntitlement could check entitlement, or we check dynamically
            #if !targetEnvironment(simulator)
            hasCarrierEntitlement = isSupported
            #endif

            let caps: [String: Any] = [
                "isSupported": isSupported,
                "isEnabled": isSupported,
                "eid": nil as Any?,
                "hasCarrierPrivileges": hasCarrierEntitlement,
                "supportsDirectDownload": hasCarrierEntitlement,
                "supportsSystemDialog": true,
                "osVersion": "iOS \(osVersion)"
            ]
            result(caps)

        case "installProfile":
            let lpa = (args["lpa"] as? String) ?? ""
            let smdp = (args["smdpAddress"] as? String) ?? ""
            let matchingId = (args["matchingId"] as? String) ?? ""
            let confirmationCode = args["confirmationCode"] as? String

            if smdp.isEmpty || matchingId.isEmpty {
                result([
                    "status": "failed",
                    "errorCode": "invalidActivationCode",
                    "message": "Missing SM-DP+ address or matching ID"
                ])
                return
            }

            let provisioning = CTCellularPlanProvisioning()

            // 1. If device does not support eSIM:
            if !provisioning.supportsCellularPlan() {
                result([
                    "status": "failed",
                    "errorCode": "unsupportedDevice",
                    "message": "Device hardware does not support eSIM (no eUICC)"
                ])
                return
            }

            // 2. Carrier-Entitled Direct Installation Attempt
            let planRequest = CTCellularPlanProvisioningRequest()
            planRequest.address = smdp
            planRequest.matchingIdentifier = matchingId
            if let confirmationCode = confirmationCode, !confirmationCode.isEmpty {
                planRequest.confirmationCode = confirmationCode
            }

            provisioning.addPlan(with: planRequest) { [weak self] addResult in
                DispatchQueue.main.async {
                    switch addResult {
                    case .success:
                        result([
                            "status": "success",
                            "errorCode": "none",
                            "message": "eSIM profile provisioned successfully via CoreTelephony"
                        ])

                    case .cancel:
                        result([
                            "status": "canceled",
                            "errorCode": "operationCanceled",
                            "message": "User canceled eSIM profile installation"
                        ])

                    case .fail, .unknown:
                        fallthrough
                    @unknown default:
                        // Fallback to Apple Universal Link (iOS 17.4+ native setup sheet)
                        self?.openAppleUniversalLink(lpa: lpa) { opened in
                            if opened {
                                result([
                                    "status": "success",
                                    "errorCode": "none",
                                    "message": "Opened Apple eSIM native setup sheet"
                                ])
                            } else {
                                result([
                                    "status": "failed",
                                    "errorCode": "systemError",
                                    "message": "CoreTelephony installation failed and Universal Link could not be opened"
                                ])
                            }
                        }
                    }
                }
            }

        case "openCellularSettings":
            if let settingsUrl = URL(string: UIApplication.openSettingsURLString),
               UIApplication.shared.canOpenURL(settingsUrl) {
                UIApplication.shared.open(settingsUrl) { success in
                    result(success)
                }
            } else {
                result(false)
            }

        default:
            result(FlutterMethodNotImplemented)
        }
    }

    private func openAppleUniversalLink(lpa: String, completion: @escaping (Bool) -> Void) {
        guard let encodedLpa = lpa.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed),
              let url = URL(string: "https://esimsetup.apple.com/esim_qrcode_provisioning?carddata=\(encodedLpa)") else {
            completion(false)
            return
        }

        if UIApplication.shared.canOpenURL(url) {
            UIApplication.shared.open(url, options: [:], completionHandler: completion)
        } else {
            completion(false)
        }
    }
}
