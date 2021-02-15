# iMRuby

## Installation

iMRuby is available through [CocoaPods](https://cocoapods.org). To install
it, simply add the following line to your Podfile:

```ruby
pod 'iMRuby', :git => 'git@github.com:tailang/iMRuby.git'
```

podfile
```ruby
 post_install do |installer|
    installer.pods_project.build_configuration_list.build_configurations.each do |configuration|
      configuration.build_settings['CLANG_ALLOW_NON_MODULAR_INCLUDES_IN_FRAMEWORK_MODULES'] = 'YES'
    end
  end
```

## Author

ping.cao

## License

iMRuby is available under the MIT license. See the LICENSE file for more info.
