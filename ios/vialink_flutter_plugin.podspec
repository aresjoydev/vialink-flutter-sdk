Pod::Spec.new do |s|
  s.name             = 'vialink_flutter_plugin'
  s.version          = '2.0.0'
  s.summary          = 'ViaLink deep linking SDK for Flutter'
  s.homepage         = 'https://vialink.app'
  s.license          = { :type => 'Proprietary' }
  s.author           = { 'ViaLink' => 'dev@vialink.app' }
  s.source           = { :path => '.' }

  s.source_files = 'Classes/**/*'
  s.vendored_frameworks = 'Frameworks/ViaLinkCore.xcframework'

  s.dependency 'Flutter'
  s.platform = :ios, '15.0'
  s.swift_version = '5.9'

  s.pod_target_xcconfig = {
    'DEFINES_MODULE' => 'YES',
    'EXCLUDED_ARCHS[sdk=iphonesimulator*]' => 'i386'
  }
end
