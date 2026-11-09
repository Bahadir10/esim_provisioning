import Cocoa
import FlutterMacOS

public final class EsimProvisioningPlugin: NSObject, FlutterPlugin {
    public static func register(with registrar: FlutterPluginRegistrar) {
        let channel = FlutterMethodChannel(
            name: "dev.flutter.telecom/esim_provisioning",
            binaryMessenger: registrar.messenger
        )
        let instance = EsimProvisioningPlugin()
        registrar.addMethodCallDelegate(instance, channel: channel)
    }

    public func handle(_ call: FlutterMethodCall, result: @escaping FlutterResult) {
        switch call.method {
        case "getCapabilities":
            let caps: [String: Any] = [
                "isSupported": false,
                "isEnabled": false,
                "eid": nil as Any?,
                "hasCarrierPrivileges": false,
                "supportsDirectDownload": false,
                "supportsSystemDialog": false,
                "osVersion": "macOS \(ProcessInfo.processInfo.operatingSystemVersionString)"
            ]
            result(caps)

        case "installProfile":
            result([
                "status": "failed",
                "errorCode": "unsupportedDevice",
                "message": "Direct eSIM profile provisioning is not supported on macOS desktop."
            ])

        case "openCellularSettings":
            result(false)

        default:
            result(FlutterMethodNotImplemented)
        }
    }
}
