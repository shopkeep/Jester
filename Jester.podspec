#
# Be sure to run `pod lib lint ${POD_NAME}.podspec' to ensure this is a
# valid spec before submitting.
#
# Any lines starting with a # are optional, but their use is encouraged
# To learn more about a Podspec see http://guides.cocoapods.org/syntax/podspec.html
#

Pod::Spec.new do |s|
  s.name             = 'Jester'
  s.version          = '0.1.0'
  s.summary          = 'A pure Swift state machine with a little bit of an Rx flavor'

# This description is used to generate tags and improve search results.
#   * Think: What does it do? Why did you write it? What is the focus?
#   * Try to keep it short, snappy and to the point.
#   * Write the description between the DESC delimiters below.
#   * Finally, don't worry about the indent, CocoaPods strips it!

  s.description      = <<-DESC
Jester is a pure swift state machine with a little bit of an Rx flavor.
                       DESC

  s.homepage         = 'https://github.com/shopkeep/Jester'
  s.license          = { :type => 'MIT', :file => 'LICENSE' }
  s.author           = 'ShopKeep'
  s.source           = { :git => 'https://github.com/shopkeep/Jester.git', :tag => s.version }
  s.ios.deployment_target = '9.0'
  s.source_files = 'Jester/Classes/**/*'
  # s.resource_bundles = {
  #   '${POD_NAME}' => ['${POD_NAME}/Assets/*.png']
  # }

  # s.public_header_files = 'Pod/Classes/**/*.h'
  # s.frameworks = 'UIKit', 'MapKit'
  s.dependency 'RxSwift', '~> 4.0'
end

