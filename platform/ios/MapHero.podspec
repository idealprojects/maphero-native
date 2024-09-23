Pod::Spec.new do |s|
    version = "#{ENV['VERSION']}"
    s.name = 'MapHero'
    s.version = version
    s.license = { :type => 'BSD', :file => "LICENSE.md" }
    s.homepage = 'https://maphero.org/'
    s.authors = { 'MapHero' => '' }
    s.summary = 'Open source vector map solution for iOS with full styling capabilities.'
    s.platform = :ios
    s.source = {
        # :http => "https://github.com/maphero/maphero-native/releases/download/ios-v#{version.to_s}/MapHero.dynamic.xcframework.zip",
        :http => "https://github.com/idealprojects/maphero-native/releases/download/0.0.1/MapHero_ios_device.framework.zip",
        :type => "zip"
    }
    s.social_media_url = 'https://mastodon.social/@maphero'
    s.ios.deployment_target = '12.0'
    s.ios.vendored_frameworks = "MapHero.xcframework"
end