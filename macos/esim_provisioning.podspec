Pod::Spec.new do |s|
  s.name             = 'esim_provisioning'
  s.version          = '0.1.0'
  s.summary          = 'macOS implementation for esim_provisioning.'
  s.description      = <<-DESC
macOS desktop implementation for esim_provisioning capability queries and LPA management.
                       DESC
  s.homepage         = 'https://github.com/Bahadir10/esim_provisioning'
  s.license          = { :file => '../LICENSE' }
  s.author           = { 'Flutter Telecom' => 'telecom@example.com' }
  s.source           = { :path => '.' }
  s.source_files     = 'Classes/**/*'
  s.dependency 'FlutterMacOS'
  s.platform         = :osx, '10.14'
  s.pod_target_xcconfig = { 'DEFINES_MODULE' => 'YES' }
  s.swift_version    = '5.9'
end
