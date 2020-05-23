# iOS Installation

## Using CocoaPods
#### NOTE: For RN >= 0.60, should be better to use CocoaPods and for RN < 0.60 use Manual installations!

To install with CocoaPods, after running `npm i` add the following to your `Podfile`:
`pod 'react-native-mapbox-gl', :path => '../node_modules/mapir-mapbox'`

```
platform :ios, '9.0'
require_relative '../node_modules/@react-native-community/cli-platform-ios/native_modules'

def add_flipper_pods!(versions = {})
  versions['Flipper'] ||= '~> 0.33.1'
  versions['DoubleConversion'] ||= '1.1.7'
  versions['Flipper-Folly'] ||= '~> 2.1'
  versions['Flipper-Glog'] ||= '0.3.6'
  versions['Flipper-PeerTalk'] ||= '~> 0.0.4'
  versions['Flipper-RSocket'] ||= '~> 1.0'

  pod 'FlipperKit', versions['Flipper'], :configuration => 'Debug'
  pod 'FlipperKit/FlipperKitLayoutPlugin', versions['Flipper'], :configuration => 'Debug'
  pod 'FlipperKit/SKIOSNetworkPlugin', versions['Flipper'], :configuration => 'Debug'
  pod 'FlipperKit/FlipperKitUserDefaultsPlugin', versions['Flipper'], :configuration => 'Debug'
  pod 'FlipperKit/FlipperKitReactPlugin', versions['Flipper'], :configuration => 'Debug'

  # List all transitive dependencies for FlipperKit pods
  # to avoid them being linked in Release builds
  pod 'Flipper', versions['Flipper'], :configuration => 'Debug'
  pod 'Flipper-DoubleConversion', versions['DoubleConversion'], :configuration => 'Debug'
  pod 'Flipper-Folly', versions['Flipper-Folly'], :configuration => 'Debug'
  pod 'Flipper-Glog', versions['Flipper-Glog'], :configuration => 'Debug'
  pod 'Flipper-PeerTalk', versions['Flipper-PeerTalk'], :configuration => 'Debug'
  pod 'Flipper-RSocket', versions['Flipper-RSocket'], :configuration => 'Debug'
  pod 'FlipperKit/Core', versions['Flipper'], :configuration => 'Debug'
  pod 'FlipperKit/CppBridge', versions['Flipper'], :configuration => 'Debug'
  pod 'FlipperKit/FBCxxFollyDynamicConvert', versions['Flipper'], :configuration => 'Debug'
  pod 'FlipperKit/FBDefines', versions['Flipper'], :configuration => 'Debug'
  pod 'FlipperKit/FKPortForwarding', versions['Flipper'], :configuration => 'Debug'
  pod 'FlipperKit/FlipperKitHighlightOverlay', versions['Flipper'], :configuration => 'Debug'
  pod 'FlipperKit/FlipperKitLayoutTextSearchable', versions['Flipper'], :configuration => 'Debug'
  pod 'FlipperKit/FlipperKitNetworkPlugin', versions['Flipper'], :configuration => 'Debug'
end

# Post Install processing for Flipper
def flipper_post_install(installer)
  installer.pods_project.targets.each do |target|
    if target.name == 'YogaKit'
      target.build_configurations.each do |config|
        config.build_settings['SWIFT_VERSION'] = '4.1'
      end
    end
  end
end

target 'MapirRN62' do
  # Pods for MapirRN62
  pod 'FBLazyVector', :path => "../node_modules/react-native/Libraries/FBLazyVector"
  pod 'FBReactNativeSpec', :path => "../node_modules/react-native/Libraries/FBReactNativeSpec"
  pod 'RCTRequired', :path => "../node_modules/react-native/Libraries/RCTRequired"
  pod 'RCTTypeSafety', :path => "../node_modules/react-native/Libraries/TypeSafety"
  pod 'React', :path => '../node_modules/react-native/'
  pod 'React-Core', :path => '../node_modules/react-native/'
  pod 'React-CoreModules', :path => '../node_modules/react-native/React/CoreModules'
  pod 'React-Core/DevSupport', :path => '../node_modules/react-native/'
  pod 'React-RCTActionSheet', :path => '../node_modules/react-native/Libraries/ActionSheetIOS'
  pod 'React-RCTAnimation', :path => '../node_modules/react-native/Libraries/NativeAnimation'
  pod 'React-RCTBlob', :path => '../node_modules/react-native/Libraries/Blob'
  pod 'React-RCTImage', :path => '../node_modules/react-native/Libraries/Image'
  pod 'React-RCTLinking', :path => '../node_modules/react-native/Libraries/LinkingIOS'
  pod 'React-RCTNetwork', :path => '../node_modules/react-native/Libraries/Network'
  pod 'React-RCTSettings', :path => '../node_modules/react-native/Libraries/Settings'
  pod 'React-RCTText', :path => '../node_modules/react-native/Libraries/Text'
  pod 'React-RCTVibration', :path => '../node_modules/react-native/Libraries/Vibration'
  pod 'React-Core/RCTWebSocket', :path => '../node_modules/react-native/'

  pod 'React-cxxreact', :path => '../node_modules/react-native/ReactCommon/cxxreact'
  pod 'React-jsi', :path => '../node_modules/react-native/ReactCommon/jsi'
  pod 'React-jsiexecutor', :path => '../node_modules/react-native/ReactCommon/jsiexecutor'
  pod 'React-jsinspector', :path => '../node_modules/react-native/ReactCommon/jsinspector'
  pod 'ReactCommon/callinvoker', :path => "../node_modules/react-native/ReactCommon"
  pod 'ReactCommon/turbomodule/core', :path => "../node_modules/react-native/ReactCommon"
  pod 'react-native-mapbox-gl', :path => '../node_modules/mapir-mapbox'
  pod 'Yoga', :path => '../node_modules/react-native/ReactCommon/yoga', :modular_headers => true

  pod 'DoubleConversion', :podspec => '../node_modules/react-native/third-party-podspecs/DoubleConversion.podspec'
  pod 'glog', :podspec => '../node_modules/react-native/third-party-podspecs/glog.podspec'
  pod 'Folly', :podspec => '../node_modules/react-native/third-party-podspecs/Folly.podspec'

  target 'MapirRN62Tests' do
    inherit! :complete
    # Pods for testing
  end

  use_native_modules!

  # Enables Flipper.
  #
  # Note that if you have use_frameworks! enabled, Flipper will not work and
  # you should disable these next few lines.
  add_flipper_pods!
  post_install do |installer|
    flipper_post_install(installer)
  end
end

target 'MapirRN62-tvOS' do
  # Pods for MapirRN62-tvOS

  target 'MapirRN62-tvOSTests' do
    inherit! :search_paths
    # Pods for testing
  end
end

```

Then run `pod install` and rebuild your project.

## Manual Installation

### Add Native Mapbox SDK Framework

Select your project in the `Project navigator`. Click `General` tab then add `node_modules/@react-native-mapbox-gl/maps/ios/Mapbox.framework` to `Embedded Binaries`. :collision: **Important, make sure you're adding it to general -> `Embedded Binaries` :collision:**

Click 'Add other' to open the file browser and select Mapbox.framework.

![](https://s3.systemlevel.com/docs-public/addother.png)

Select the 'Copy items if needed' checkbox.

![](https://s3.systemlevel.com/docs-public/copyitems.png)

After adding Mapbox.framework it should be listed in your Embedded Binaries:

![](https://s3.systemlevel.com/docs-public/embeddedbinaries.png)

<!-- ![](https://cldup.com/s4U3JfS_-l.png) -->

### Add React Native Mapbox SDK Files

In Xcode's `Project navigator`, right click on the `Libraries` folder ➜ `Add Files to <...>`. Add `node_modules/@react-native-mapbox-gl/maps/ios/RCTMGL.xcodeproj`.

![](https://s3.systemlevel.com/docs-public/addfilesto.png)

Then in Xcode navigate to `Build Phases` click on it and you should see `Link Binary with Libraries`, we need to add `libRCTMGL.a`.

![](https://s3.systemlevel.com/docs-public/buildphases.png)

After you add 'libRCTMGL.a' it should be listed as such:

![](https://s3.systemlevel.com/docs-public/buildphasesadd.png)

### Add Framework Header Search Paths

In the `Build Settings` of your application target search for `FRAMEWORK_SEARCH_PATHS`.

![](https://s3.systemlevel.com/docs-public/frameworksearch.png)

Add `$(PROJECT_DIR)/../node_modules/@react-native-mapbox-gl/maps/ios` non-recursive to your `Framework Search Paths`.

![](https://s3.systemlevel.com/docs-public/frameworksearchadd.png)

**Important** If there is a select input under `Debug` line, choose `Any iOS SDK`.

### Add Run Script

In the `Build Phases` tab, click the plus sign and then `New Run Script Phase`.

![](https://cldup.com/jgt8p_dHjD.png)

Open the newly added `Run Script` and paste:

```bash
 "${BUILT_PRODUCTS_DIR}/${FRAMEWORKS_FOLDER_PATH}/Mapbox.framework/strip-frameworks.sh"
```

![](https://s3.systemlevel.com/docs-public/runscript.png)

If you have any issues related to not being able to find strip-frameworks.sh during your build process, click and drag the strip-frameworks.sh file into the xcode editor:

![](https://s3.systemlevel.com/docs-public/strip-frameworks.png)

![](https://s3.systemlevel.com/docs-public/drag.png)



Checkout the [example application](/example/README.md) to see how it's configured for an example.
