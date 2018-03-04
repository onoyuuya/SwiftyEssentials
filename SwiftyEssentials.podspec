Pod::Spec.new do |s|
  s.name         = "SwiftyEssentials"
  s.version      = "0.0.1"
  s.summary      = "A collection of extensions to make iOS development easier."
  s.homepage     = "https://github.com/onoyuuya/SwiftyEssentials"
  s.license      = { :type => "MIT", :file => "LICENSE" }
  s.author       = { "onoyuuya" => "onoyuuya@live.jp" }
  s.platform     = :ios, "10.0"
  s.source       = { :git => "https://github.com/onoyuuya/SwiftyEssentials.git", :tag => "#{s.version}" }
  s.source_files  = "Extensions.swift"
  s.requires_arc = true
  s.static_framework = true
  s.swift_version = "4.0.3"
end
