Pod::Spec.new do |s|
  s.name             = 'vialink_flutter_plugin'
  s.version          = '3.2.7'
  s.summary          = 'ViaLink Flutter Plugin - 딥링크, 디퍼드 딥링킹, 이벤트 추적'
  s.description      = <<-DESC
ViaLink Flutter 플러그인입니다. 네이티브 ViaLinkCore SDK를 브릿지하여
딥링크 라우팅, 디퍼드 딥링킹, 이벤트 추적, 결제 어트리뷰션을 제공합니다.
                       DESC
  s.homepage         = 'https://vialink.app'
  s.license          = { :type => 'MIT', :file => '../LICENSE' }
  s.author           = { 'Aresjoy Inc' => 'support@aresjoy.com' }
  s.source           = { :path => '.' }
  s.source_files     = 'Classes/**/*'
  s.dependency 'Flutter'
  s.platform         = :ios, '13.0'

  # 네이티브 ViaLinkCore XCFramework 포함
  s.vendored_frameworks = 'Frameworks/ViaLinkCore.xcframework'

  s.pod_target_xcconfig = { 'DEFINES_MODULE' => 'YES' }
  s.swift_version = '5.0'
end
