Pod::Spec.new do |s|
  s.name             = 'esim_provisioning'
  s.version          = '0.1.0'
  s.summary          = 'iOS CoreTelephony and Universal Link eSIM provisioning plugin.'
  s.description      = <<-DESC
Production-grade iOS eSIM provisioning using CTCellularPlanProvisioning and Apple Universal Link eSIM setup.
                       DESC
  s.homepage         = 'https://github.com/Bahadir10/esim_provisioning'
  s.license          = { :file => '../LICENSE' }
  s.author           = { 'Flutter Telecom' => 'telecom@example.com' }
  s.source           = { :path => '.' }
  s.source_files     = 'Classes/**/*'
  s.dependency 'Flutter'
  s.platform         = :ios, '13.0'
  s.frameworks       = 'CoreTelephony', 'UIKit'
  s.pod_target_xcconfig = { 'DEFINES_MODULE' => 'YES', 'EXCLUDED_ARCHS[sdk=iphonesimulator*]' => 'i386' }
  s.swift_version    = '5.9'
end
