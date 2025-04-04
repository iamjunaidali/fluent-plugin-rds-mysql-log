# frozen_string_literal: true

require 'bundler/setup'
require 'test/unit'
require 'webmock/test_unit'
require 'simplecov'

SimpleCov.start do
  add_filter '/test/'
end

$LOAD_PATH.unshift(File.join(__dir__, '..', 'lib'))
$LOAD_PATH.unshift(__dir__)
require 'fluent/test'
require 'fluent/test/helpers'
require 'fluent/test/driver/input'
require 'fluent/plugin/in_rds_mysql_log'

module Test
  module Unit
    class TestCase
      include Fluent::Test::Helpers
      extend Fluent::Test::Helpers
    end
  end
end
