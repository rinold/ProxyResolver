#
# Be sure to run `pod lib lint ProxyResolver.podspec' to ensure this is a
# valid spec before submitting.
#
# Any lines starting with a # are optional, but their use is encouraged
# To learn more about a Podspec see https://guides.cocoapods.org/syntax/podspec.html
#

Pod::Spec.new do |s|
  s.name             = 'ProxyResolver'
  s.version          = '0.3.1'
  s.summary          = 'Simple resolution of user proxy settings for macOS'

  s.description      = <<-DESC
  ProxyResolver allows simply resolve the actual proxy information from users
  system configuration and could be used for setting up Stream-based connections,
  for example for Web Sockets.
                       DESC

  s.homepage         = 'https://github.com/rinold/ProxyResolver'
  s.license          = { :type => 'MIT', :file => 'LICENSE' }
  s.author           = { 'rinold' => 'mihail.churbanov@gmail.com' }
  s.source           = { :git => 'https://github.com/rinold/ProxyResolver.git', :tag => s.version.to_s }
  s.social_media_url = 'https://twitter.com/rinold_nn'

  s.ios.deployment_target = "10.0"
  s.osx.deployment_target = "10.10"

  s.source_files = 'ProxyResolver/Classes/**/*'

  # s.resource_bundles = {
  #   'ProxyResolver' => ['ProxyResolver/Assets/*.png']
  # }

  # s.public_header_files = 'Pod/Classes/**/*.h'
  # s.frameworks = 'Cocoa'
  # s.dependency 'AFNetworking', '~> 2.3'
end
