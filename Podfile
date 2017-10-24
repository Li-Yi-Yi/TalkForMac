# Uncomment the next line to define a global platform for your project
# SnapKit 3.0.0+ requires macOS 10.11+
platform :osx, '10.11'
inhibit_all_warnings!

target 'WantTalkMac' do
  # Comment the next line if you're not using Swift and don't want to use dynamic frameworks
  use_frameworks!

  # Pods for WantTalkMac
    pod 'SwiftyJSON'
    pod 'RxSwift'
    pod 'RxCocoa'
    pod 'RxBlocking'
    pod 'Cent'
    pod 'SnapKit', '~> 3.2.0'
    pod 'Bolts-Swift'
    pod 'Dollar'
    pod 'Kingfisher',  :git => 'https://github.com/onevcat/Kingfisher.git'
    pod 'Fabric'
    pod 'Crashlytics'
    pod 'ReachabilitySwift', '~> 3'     #实时监测网络连接状态
    pod 'Alamofire'
    pod 'XMPPFramework'
  #Objective-C
    pod 'RealmSwift', '~> 2.8.3'  #数据库
    pod 'XCGLogger' #log日志
    pod 'Zip' #压缩

  target 'WantTalkMacTests' do
    inherit! :search_paths
    # Pods for testing
  end

  target 'WantTalkMacUITests' do
    inherit! :search_paths
    # Pods for testing
  end

end

post_install do |installer|
  installer.pods_project.targets.each do |target|
    target.build_configurations.each do |config|
      config.build_settings['SWIFT_VERSION'] = '3.0'
      config.build_settings['MACOSX_DEPLOYMENT_TARGET'] = '10.11'
    end
  end
end
