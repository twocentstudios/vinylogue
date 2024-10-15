source 'https://github.com/CocoaPods/Specs.git'

platform :ios, '15.0'

inhibit_all_warnings!

def shared_pods
    pod 'AFNetworking', '1.3.3'
    pod 'ReactiveCocoa', '2.3.1'
    pod 'ViewUtils', '1.1.2'
    pod 'UIViewDrawRectBlock', '0.0.1'
    pod 'SDURLCache', '1.3.0'
end

target 'vinylogue' do
    use_frameworks!
    shared_pods
end

post_install do |installer|
  installer.pods_project.targets.each do |target|
    target.build_configurations.each do |config|
      config.build_settings['IPHONEOS_DEPLOYMENT_TARGET'] = '15.0'
    end
  end
end
