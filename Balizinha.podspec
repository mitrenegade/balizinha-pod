#
# Be sure to run `pod lib lint balizinha.podspec' to ensure this is a
# valid spec before submitting.
#
# Any lines starting with a # are optional, but their use is encouraged
# To learn more about a Podspec see https://guides.cocoapods.org/syntax/podspec.html
#

Pod::Spec.new do |s|
  s.name             = 'Balizinha'
  s.version          = '0.2.6'
  s.summary          = 'Services and models for the Balizinha backend'

# This description is used to generate tags and improve search results.
#   * Think: What does it do? Why did you write it? What is the focus?
#   * Try to keep it short, snappy and to the point.
#   * Write the description between the DESC delimiters below.
#   * Finally, don't worry about the indent, CocoaPods strips it!

  s.description      = <<-DESC
Balizinha is a backend service for event management that includes models and services. 
The models include Events, Leagues, Players, and Actions.
The services include Auth, Push, and Stripe.
The demo project is an admin project that allows the user to check out their dashboard.
                       DESC

  s.homepage         = 'https://gist.github.com/mitrenegade/d0783b88748c7adfd2039bd62e1680a9'
  # s.screenshots     = 'www.example.com/screenshots_1', 'www.example.com/screenshots_2'
  s.license          = { :type => 'MIT', :file => 'LICENSE' }
  s.author           = { 'bobbyren' => 'bobbyren@gmail.com' }
  s.source           = { :git => 'https://bitbucket.org/renderapps/balizinha-pod.git', :tag => s.version.to_s }
  # s.social_media_url = 'https://twitter.com/<TWITTER_USERNAME>'

  s.ios.deployment_target = '8.0'
  s.swift_version = '4.1'
  s.static_framework = true

  s.source_files = 'Balizinha/Classes/**/*'
  
  # s.resource_bundles = {
  #   'Balizinha' => ['Balizinha/Assets/*.png']
  # }

  # s.public_header_files = 'Pod/Classes/**/*.h'
  s.frameworks = 'UIKit', 'MapKit', 'FirebaseCore', 'FirebaseAuth', 'FirebaseDatabase', 'FirebaseStorage', 'FirebaseRemoteConfig', 'FirebaseMessaging', 'FirebaseAnalytics'  
  s.dependency 'Firebase'
  s.dependency 'Firebase/Core'
  s.dependency 'Firebase/Auth'
  s.dependency 'Firebase/Database'
  s.dependency 'Firebase/Storage'
  s.dependency 'Firebase/RemoteConfig'
  s.dependency 'Firebase/Messaging'
  s.dependency 'Firebase/Analytics'
  s.dependency 'RxSwift'
  s.dependency 'RxCocoa'
  s.dependency 'RxOptional'

  s.pod_target_xcconfig = {
    'FRAMEWORK_SEARCH_PATHS' => '$(inherited) $(PODS_ROOT)/Firebase $(PODS_ROOT)/FirebaseCore/Frameworks $(PODS_ROOT)/FirebaseRemoteConfig/Frameworks $(PODS_ROOT)/FirebaseInstanceID/Frameworks $(PODS_ROOT)/FirebaseAnalytics/Frameworks'
  }
end
