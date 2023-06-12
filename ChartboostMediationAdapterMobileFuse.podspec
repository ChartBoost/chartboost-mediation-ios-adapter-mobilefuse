Pod::Spec.new do |spec|
  spec.name        = 'ChartboostMediationAdapterMobileFuse'
  spec.version     = '4.1.4.4.0'
  spec.license     = { :type => 'MIT', :file => 'LICENSE.md' }
  spec.homepage    = 'https://github.com/ChartBoost/chartboost-mediation-ios-adapter-mobilefuse'
  spec.authors     = { 'Chartboost' => 'https://www.chartboost.com/' }
  spec.summary     = 'Chartboost Mediation iOS SDK Reference adapter.'
  spec.description = 'MobileFuse Adapters for mediating through Chartboost Mediation. Supported ad formats: banner, interstitial, rewarded.'

  # Source
  spec.module_name  = 'ChartboostMediationAdapterMobileFuse'
  spec.source       = { :git => 'https://github.com/ChartBoost/chartboost-mediation-ios-adapter-mobilefuse.git', :tag => spec.version }
  spec.source_files = 'Source/**/*.{swift}'

  # Minimum supported versions
  spec.swift_version         = '5.0'
  spec.ios.deployment_target = '10.0'

  # System frameworks used
  spec.ios.frameworks = ['Foundation', 'UIKit']
  
  # This adapter is compatible with all Chartboost Mediation 4.X versions of the SDK.
  spec.dependency 'ChartboostMediationSDK', '~> 4.0'

  # Partner network SDK and version that this adapter is certified to work with.
  spec.dependency 'MobileFuseSDK', '1.4.4'

  # Indicates, that if use_frameworks! is specified, the pod should include a static library framework.
  spec.static_framework = true
end
