# coding: utf-8
lib = File.expand_path('../lib', __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require 'flickpaper/version'

Gem::Specification.new do |spec|
  spec.name          = "flickpaper"
  spec.version       = Flickpaper::VERSION
  spec.authors       = ["Andrew Tongen"]
  spec.email         = ["atongen@gmail.com"]
  spec.summary       = %q{Sets your GNOME or OSX wallpaper to a recent interesting photo from flickr}
  spec.description   = %q{Sets your GNOME or OSX wallpaper to a recent interesting photo from flickr}
  spec.homepage      = "http://github.com/atongen/flickpaper"
  spec.license       = "MIT"

  spec.files         = `git ls-files -z`.split("\x0")
  spec.executables   = spec.files.grep(%r{^bin/}) { |f| File.basename(f) }
  spec.test_files    = spec.files.grep(%r{^(test|spec|features)/})
  spec.require_paths = ["lib"]

  spec.add_development_dependency "bundler", "~> 1.7"
  spec.add_development_dependency "rake", "~> 10.0"

  spec.add_dependency 'flickraw'
end
