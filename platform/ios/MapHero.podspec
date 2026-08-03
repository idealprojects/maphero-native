Pod::Spec.new do |s|
    version = "1.0.4"

    s.name = 'MapHero'
    s.version = version
    s.license = { :type => 'BSD', :file => "LICENSE.md" }
    s.homepage = 'https://maphero.io/'
    s.authors = { 'MapHero' => '' }
    s.summary = 'Vector map solution for iOS with full styling capabilities.'
    s.platform = :ios
    s.source = {
        :http => "https://github.com/idealprojects/maphero-ios/releases/download/1.0.4/MapHero.dynamic.xcframework.zip",
        :type => "zip"
    }
    s.social_media_url  = 'https://maphero.io'
    s.ios.deployment_target = '12.0'
    s.ios.vendored_frameworks = "MapHero.xcframework"
end
