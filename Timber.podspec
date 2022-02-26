
Pod::Spec.new do |s|

  s.name         = "Timber"
  s.version      = "1.0"
  s.summary      = "iOS and macOS app logging made easy. Batteries Included."
  s.description  = <<-DESC
                   A logging library that provides a powerful and easy to use API.
                   Works on macOS and iOS platforms.
                   DESC

  s.ios.deployment_target = "10.0"
  s.osx.deployment_target = "10.15"
  
  s.homepage     = "https://github.com/cbess/Timber"
  s.license      = { :type => 'MIT', :file => 'LICENSE' }
  s.author       = { "Christopher Bess" => "email@address.com" }

  s.source       = { :git => "https://github.com/cbess/Timber.git", :tag => "v#{s.version}" }
  
  s.source_files  = 'Timber/Classes/CBTimber/*.{h,m}'

end
