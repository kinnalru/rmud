# frozen_string_literal: true

lib = File.expand_path('lib', __dir__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require 'rmud/version'

Gem::Specification.new do |spec|
  spec.name          = 'rmud'
  spec.version       = ENV['BUILDVERSION'].to_i > 0 ? "#{RMud::VERSION}.#{ENV['BUILDVERSION'].to_i}" : RMud::VERSION
  spec.authors       = ['Samoilenko Yuri']
  spec.email         = ['kinnalru@gmail.com']

  spec.summary       = 'Ruby bot for MUD'
  spec.description   = 'Ruby bot for MUD(tintin++)'

  spec.files         = Dir['bin/*', 'lib/**/*', 'Gemfile*', 'LICENSE.txt', 'README.md']
  spec.bindir        = 'bin'
  spec.require_paths = ['lib']

  spec.add_runtime_dependency 'activesupport', '~> 6.0'
  #spec.add_runtime_dependency 'daemons'
  spec.add_runtime_dependency 'colorize'
  spec.add_runtime_dependency 'concurrent-ruby'

  spec.add_development_dependency 'byebug'
end

