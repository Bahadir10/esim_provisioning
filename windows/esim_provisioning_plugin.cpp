#include "esim_provisioning_plugin.h"
#include "include/esim_provisioning/esim_provisioning_plugin_c_api.h"

namespace esim_provisioning {

void EsimProvisioningPlugin::RegisterWithRegistrar(
    flutter::PluginRegistrarWindows *registrar) {
  auto channel = std::make_unique<flutter::MethodChannel<flutter::EncodableValue>>(
      registrar->messenger(), "dev.flutter.telecom/esim_provisioning",
      &flutter::StandardMethodCodec::GetInstance());

  auto plugin = std::make_unique<EsimProvisioningPlugin>(std::move(channel));
  registrar->AddPlugin(std::move(plugin));
}

EsimProvisioningPlugin::EsimProvisioningPlugin(
    std::unique_ptr<flutter::MethodChannel<flutter::EncodableValue>> channel)
    : channel_(std::move(channel)) {
  channel_->SetMethodCallHandler(
      [this](const auto &call, auto result) {
        this->HandleMethodCall(call, std::move(result));
      });
}

EsimProvisioningPlugin::~EsimProvisioningPlugin() = default;

void EsimProvisioningPlugin::HandleMethodCall(
    const flutter::MethodCall<flutter::EncodableValue> &method_call,
    std::unique_ptr<flutter::MethodResult<flutter::EncodableValue>> result) {
  const auto &method = method_call.method_name();

  if (method == "getCapabilities") {
    flutter::EncodableMap caps;
    caps[flutter::EncodableValue("isSupported")] = flutter::EncodableValue(false);
    caps[flutter::EncodableValue("isEnabled")] = flutter::EncodableValue(false);
    caps[flutter::EncodableValue("hasCarrierPrivileges")] = flutter::EncodableValue(false);
    caps[flutter::EncodableValue("supportsDirectDownload")] = flutter::EncodableValue(false);
    caps[flutter::EncodableValue("supportsSystemDialog")] = flutter::EncodableValue(false);
    caps[flutter::EncodableValue("osVersion")] = flutter::EncodableValue("Windows Desktop");
    result->Success(flutter::EncodableValue(caps));
    return;
  }

  if (method == "installProfile") {
    flutter::EncodableMap res;
    res[flutter::EncodableValue("status")] = flutter::EncodableValue("failed");
    res[flutter::EncodableValue("errorCode")] = flutter::EncodableValue("unsupportedDevice");
    res[flutter::EncodableValue("message")] =
        flutter::EncodableValue("Direct eSIM provisioning is not supported on Windows desktop.");
    result->Success(flutter::EncodableValue(res));
    return;
  }

  if (method == "openCellularSettings") {
    result->Success(flutter::EncodableValue(false));
    return;
  }

  result->NotImplemented();
}

}  // namespace esim_provisioning

void EsimProvisioningPluginCApiRegisterWithRegistrar(
    FlutterDesktopPluginRegistrarRef registrar) {
  esim_provisioning::EsimProvisioningPlugin::RegisterWithRegistrar(
      flutter::PluginRegistrarManager::GetInstance()
          ->GetRegistrar<flutter::PluginRegistrarWindows>(registrar));
}
