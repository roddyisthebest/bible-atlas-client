# Uncomment the next line to define a global platform for your project
# platform :ios, '9.0'

# 최소 플랫폼은 네 프로젝트에 맞춰 지정(예: iOS 15 이상이면 '15.0')
platform :ios, '13.0'
project 'BibleAtlas', { 'Debug' => :debug, 'Release' => :release }

target 'BibleAtlas' do
  use_frameworks!

  pod "Alamofire"
  pod "OHHTTPStubs"
  pod "OHHTTPStubs/Swift"
  pod "RxSwift"
  pod "RxCocoa"
  pod "SnapKit"
  pod "KeychainAccess"
  pod "Kingfisher"
  pod "GoogleSignIn"
  pod "FirebaseCore"
  pod "RxTest"
  pod "RxBlocking"

  target 'BibleAtlasTests' do
    inherit! :search_paths
  end
end

post_install do |installer|
  require 'xcodeproj'

  app_project_path = 'BibleAtlas.xcodeproj'      # ← 프로젝트 파일명 확인
  target_names = ['BibleAtlas', 'BibleAtlasTests']  # ← 타깃 이름 확인

  config_map = {
    'Debug'   => 'Config/Debug.xcconfig',
    'Release' => 'Config/Release.xcconfig'
  }

  project = Xcodeproj::Project.open(app_project_path)

  target_names.each do |tname|
    t = project.targets.find { |x| x.name == tname }
    next unless t
    t.build_configurations.each do |cfg|
      next unless config_map[cfg.name]
      file_ref = project.files.find { |f| f.path == config_map[cfg.name] } || project.new_file(config_map[cfg.name])
      cfg.base_configuration_reference = file_ref
    end
  end

  # ===============================
  # 🔧 모든 Pod 타깃의 최소 iOS 버전을
  #    강제로 13.0 이상으로 맞추고 싶을 때
  #    아래 블럭 주석만 풀어서 사용하면 됨
  # ===============================
  #
  installer.generated_projects.each do |pod_project|
    pod_project.targets.each do |target|
      target.build_configurations.each do |config|
        # 여기서 원하는 버전으로 강제 세팅 (예: '13.0', '14.0' 등)
        config.build_settings['IPHONEOS_DEPLOYMENT_TARGET'] = '13.0'
      end
    end
  end
  #
  # ===============================

  project.save
end
