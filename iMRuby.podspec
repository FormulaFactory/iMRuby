#
# Be sure to run `pod lib lint iMRuby.podspec' to ensure this is a
# valid spec before submitting.
#
# Any lines starting with a # are optional, but their use is encouraged
# To learn more about a Podspec see https://guides.cocoapods.org/syntax/podspec.html
#

Pod::Spec.new do |s|
  s.name             = 'iMRuby'
  s.version          = '0.1.0'
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
  
  s.dependency 'MRubyFramework', '2.1.2'

  s.vendored_library = 'iMRuby/Classes/MRBLibffi/libffi.a'
end
