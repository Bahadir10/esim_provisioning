#ifndef FLUTTER_PLUGIN_ESIM_PROVISIONING_PLUGIN_H_
#define FLUTTER_PLUGIN_ESIM_PROVISIONING_PLUGIN_H_

#include <flutter/method_channel.h>
#include <flutter/plugin_registrar_windows.h>
#include <flutter/standard_method_codec.h>

#include <memory>

namespace esim_provisioning {

class EsimProvisioningPlugin : public flutter::Plugin {
 public:
  static void RegisterWithRegistrar(flutter::PluginRegistrarWindows *registrar);

  explicit EsimProvisioningPlugin(
      std::unique_ptr<flutter::MethodChannel<flutter::EncodableValue>> channel);

  virtual ~EsimProvisioningPlugin();

  EsimProvisioningPlugin(const EsimProvisioningPlugin &) = delete;
  EsimProvisioningPlugin &operator=(const EsimProvisioningPlugin &) = delete;

 private:
  void HandleMethodCall(
      const flutter::MethodCall<flutter::EncodableValue> &method_call,
      std::unique_ptr<flutter::MethodResult<flutter::EncodableValue>> result);

  std::unique_ptr<flutter::MethodChannel<flutter::EncodableValue>> channel_;
};

}  // namespace esim_provisioning

#endif  // FLUTTER_PLUGIN_ESIM_PROVISIONING_PLUGIN_H_
