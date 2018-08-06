#
# To learn more about a Podspec see http://guides.cocoapods.org/syntax/podspec.html
#
Pod::Spec.new do |s|
  s.name             = 'flutter_inapp_purchase'
  s.version          = '0.0.1'
  s.summary          = 'In App Purchase plugin for flutter. This project has been forked by react-native-iap and we are willing to share same experience with that on react-native.'
  s.description      = <<-DESC
In App Purchase plugin for flutter. This project has been forked by react-native-iap and we are willing to share same experience with that on react-native.
                       DESC
  s.homepage         = 'http://example.com'
  s.license          = { :file => '../LICENSE' }
  s.author           = { 'Your Company' => 'email@example.com' }
  s.source           = { :path => '.' }
  s.source_files = 'Classes/**/*'
  s.public_header_files = 'Classes/**/*.h'
  s.dependency 'Flutter'
  
  s.ios.deployment_target = '8.0'
end

