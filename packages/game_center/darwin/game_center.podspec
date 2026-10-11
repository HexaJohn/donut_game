Pod::Spec.new do |s|
  s.name             = 'game_center'
  s.version          = '0.1.0'
  s.summary          = 'Game Center sign-in and real-time matches for Donut.'
  s.homepage         = 'https://acrovisuals.com'
  s.license          = { :type => 'Proprietary' }
  s.author           = 'Acro Visuals'
  s.source           = { :path => '.' }
  s.source_files     = 'Classes/**/*'
  s.ios.dependency 'Flutter'
  s.osx.dependency 'FlutterMacOS'
  s.ios.deployment_target = '15.0'
  s.osx.deployment_target = '12.0'
  s.frameworks       = 'GameKit'
  s.swift_version    = '5.0'
end
