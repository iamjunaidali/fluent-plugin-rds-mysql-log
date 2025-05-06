# frozen_string_literal: true

lib = File.expand_path('lib', __dir__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)

Gem::Specification.new do |spec|
  spec.name          = 'fluent-plugin-rds-mysql-log'
  spec.version       = '0.1.13'
  spec.authors       = ['Junaid Ali']
  spec.email         = ['jonnie36@yahoo.com']
  spec.summary       = 'Amazon RDS Mysql logs input plugin'
  spec.description   = 'fluentd plugin for Amazon RDS Mysql logs input'
  spec.homepage      = 'https://github.com/iamjunaidali/fluent-plugin-rds-mysql-log'
  
  spec.metadata["homepage_uri"] = spec.homepage
  spec.metadata["source_code_uri"] = 'https://github.com/iamjunaidali/fluent-plugin-rds-mysql-log'
  
  spec.license       = 'MIT'
  spec.required_ruby_version = '>= 2.7.0'

  spec.files         = `git ls-files -z`.split("\x0")
  spec.executables   = spec.files.grep(%r{^bin/}) { |f| File.basename(f) }
  spec.test_files    = spec.files.grep(%r{^(test|spec|features)/})
  spec.require_paths = ['lib']

  spec.add_dependency 'aws-sdk-ec2', '~> 1.5'
  spec.add_dependency 'aws-sdk-rds', '~> 1.2'
  spec.add_dependency 'fluentd', '>= 0.14.0', '< 2'

  spec.add_development_dependency 'bundler', '~> 2.6'
  spec.add_development_dependency 'rake', '~> 13.2'
  spec.add_development_dependency 'simplecov', '~>0.22'
  spec.add_development_dependency 'test-unit', '~> 3.6'
  spec.add_development_dependency 'webmock', '~>3.2'
end
