# frozen_string_literal: true

require 'rubygems'
require 'bundler'

require 'time'
require 'json'
require 'logger'
require 'securerandom'

require 'faraday'
require 'puma'
require 'redis'
require 'roda'
require 'ffaker'

ENV['APP_ROOT'] = File.expand_path('..', __dir__)
$LOAD_PATH.unshift(File.expand_path('..', __dir__))

require 'config/constants'
require 'config/open_telemetry'
require 'config/logger'

%w[services routes].each do |folder|
  Dir[File.expand_path(File.join(File.dirname(__FILE__), "../#{folder}/**/*.rb"))].sort.each { |file| require file }
end
