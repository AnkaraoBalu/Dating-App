Pod::Spec.new do |spec|
  spec.name = 'FaceTecSDK'
  spec.version = '10.1.23'
  spec.summary = 'FaceTec iOS device SDK for Just2 verification.'
  spec.homepage = 'https://dev.facetec.com/'
  spec.license = { :type => 'Commercial' }
  spec.author = 'FaceTec'
  spec.platform = :ios, '16.0'
  spec.source = { :git => 'https://dev.facetec.com/' }
  spec.vendored_frameworks = 'FaceTecSDK.xcframework'
end
