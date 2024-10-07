# frozen_string_literal: true

require 'opentelemetry/common'
require 'opentelemetry/sdk'
require 'opentelemetry/exporter/otlp'
require 'opentelemetry/instrumentation/redis'
require 'opentelemetry/instrumentation/rack'
require 'opentelemetry/instrumentation/faraday'

OpenTelemetry::SDK.configure do |config|
  config.service_name = Constants::APPLICATION_NAME
  config.service_version = Constants::APPLICATION_VERSION
  config.use('OpenTelemetry::Instrumentation::Rack')
  config.use('OpenTelemetry::Instrumentation::Faraday')
  config.use('OpenTelemetry::Instrumentation::Redis')
end

OpenTelemetry.tracer_provider.tracer(
  Constants::APPLICATION_NAME,
  Constants::APPLICATION_VERSION
)
