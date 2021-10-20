#
# Be sure to run `pod lib lint iMRuby.podspec' to ensure this is a
# valid spec before submitting.
#
# Any lines starting with a # are optional, but their use is encouraged
# To learn more about a Podspec see https://guides.cocoapods.org/syntax/podspec.html
#

Pod::Spec.new do |s|
  s.name             = 'iMRuby'
  s.version          = '0.1.2'
  s.summary          = 'iMRuby is a bridge between ObjC with Ruby(Mruby)'

  s.description      = <<-DESC
  iMRuby is a bridge between ObjC with Ruby(Mruby),
  like JavascriptCore framework.
                       DESC

  s.homepage         = 'https://github.com/tailang/iMRuby'
  s.license          = { :type => 'MIT', :file => 'LICENSE' }
  s.author           = { 'ping.cao' => 'caopingcpu@163.com' }
  s.source           = { :git => 'https://github.com/tailang/iMRuby.git', :tag => s.version.to_s }

  s.ios.deployment_target = '9.0'

  s.source_files = 'iMRuby/Classes/**/*'

  s.resource_bundles = {
       'iMRuby' => ['iMRuby/Assets/**/*']
  }

  s.pod_target_xcconfig = {"CLANG_ALLOW_NON_MODULAR_INCLUDES_IN_FRAMEWORK_MODULES" => "YES", 'VALID_ARCHS' => 'x86_64 armv7 arm64' }
  
  s.dependency 'MRubyFramework', '2.1.2.1'

  s.vendored_library = 'iMRuby/Classes/MRBLibffi/libffi.a'
end
