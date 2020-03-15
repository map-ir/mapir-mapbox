require 'json'

package = JSON.parse(File.read(File.join(__dir__, 'package.json')))

Pod::Spec.new do |s|
  s.name		= "mapir-react-native"
  s.summary		= "React Native Component for Mapbox GL"
  s.version		= package['version']
  s.authors		= { "Map.ir" => "info@map.ir" }
  s.homepage    	= "https://github.com/@map-ir/mapir-mapbox#readme"
  s.license     	= "MIT"
  s.platform    	= :ios, "8.0"
  s.source      	= { :git => "https://github.com/@map-ir/mapir-mapbox.git" }
  s.source_files	= "ios/RCTMGL/**/*.{h,m}"

  s.dependency 'MapirMapKit', '~> 3.0'
  s.dependency 'React'
end
