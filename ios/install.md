# iOS Installation

## Using CocoaPods

To install with CocoaPods, add the following to your `Podfile`:

```
  # Map.ir
  pod 'mapir-react-native', :path => '../node_modules/mapir-mapbox'

  # Make also sure you have use_frameworks! enabled
  use_frameworks!
```

Then run `pod install` and rebuild your project.

## React-Native > `0.60.0`

If you are using autolinking feature introduced in React-Native `0.60.0` you do not need any additional steps.

Checkout the [example application](/example/README.md) to see how it's configured for an example.
