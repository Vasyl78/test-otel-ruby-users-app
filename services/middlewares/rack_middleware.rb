# frozen_string_literal: true

module Middlewares
  class RackMiddleware
    def initialize(app)
      @app = app
      @logger = LOGGER
      @tracer = LOCAL_TRACER
    end

    def call(env)
      getter = OpenTelemetry::Common::Propagation.rack_env_getter
      context = OpenTelemetry.propagation.extract(env, getter: getter)

      OpenTelemetry::Context.with_current(context) do
        @tracer.in_span(env["PATH_INFO"], kind: :server) do |span|
          log_execution(env, span)
        end
      end
    end

    def log_execution(env, span)
      request_log_entry = init_log(env)
      status, headers, response = @app.call(env)
      request_log_entry[:status] = status
      request_log_entry[:headers] = headers
      [status, headers, response]
    rescue StandardError => e
      on_error(request_log_entry, e, span)
    ensure
      setter = OpenTelemetry::Context::Propagation.text_map_setter
      OpenTelemetry.propagation.inject(headers, setter: setter)
      end_log(request_log_entry, env)
    end

    def init_log(env)
      {
        msg: "Processed HTTP call",
        peer: env["HTTP_X_FORWARDED_FOR"] || env["REMOTE_ADDR"],
        user: env["REMOTE_USER"],
        method: env["REQUEST_METHOD"],
        path: env["PATH_INFO"],
        query: env["QUERY_STRING"],
        protocol: env["SERVER_PROTOCOL"],
        started: Time.now
      }
    end

    def on_error(request_log_entry, error, span)
      request_log_entry[:error] = error
      request_log_entry[:stack_trace] = error.backtrace
      headers = { "content-type" => "application/json" }
      response = { trace_id: span.context.hex_trace_id, span_id: span.context.hex_span_id, error: error.message }
      span.record_exception(error)
      [500, headers, StringIO.new(response.to_json)]
    end

    def end_log(request_log_entry, env)
      request_log_entry[:request] = env["roda.json_params"]
      request_log_entry[:finished] = Time.now
      request_log_entry[:elapsed_ms] = ((request_log_entry[:finished] - request_log_entry[:started]) * 1000).round(4)
      output(request_log_entry)
    end

    def output(request_log_entry)
      if request_log_entry[:error]
        @logger.error(request_log_entry.to_json)
      else
        @logger.info(request_log_entry.to_json)
      end
    end
  end
end
