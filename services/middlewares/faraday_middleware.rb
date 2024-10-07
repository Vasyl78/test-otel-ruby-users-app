# frozen_string_literal: true

module Middlewares
  class FaradayMiddleware
    def initialize(app = nil, parse_json: false)
      @app = app
      @logger = LOGGER
      @tracer = LOCAL_TRACER
      @parse_json = parse_json
    end

    def call(request_env)
      @tracer.in_span(request_env.url.to_s, kind: :client) do |span|
        log_execution(request_env, span)
      end
    end

    private

    def log_execution(request_env, span)
      OpenTelemetry.propagation.inject(request_env.request_headers)
      request_log_entry = init_log(request_env)
      @app.call(request_env).on_complete do |response_env|
        end_log(request_log_entry, response_env)
      end
    rescue StandardError => e
      on_error(request_log_entry, e, span)
      raise e
    ensure
      output(request_log_entry)
    end

    def init_log(request_env)
      {
        msg: "Received HTTP response",
        peer: request_env.url.host,
        path: request_env.url.path,
        query: request_env.url.query,
        protocol: request_env.url.scheme,
        method: request_env.method,
        headers: request_env.request_headers,
        body: request_env.body,
        started: Time.now
      }
    end

    def on_error(request_log_entry, error, span)
      request_log_entry[:error] = error
      request_log_entry[:stack_trace] = error.backtrace
      span.record_exception(error)
    end

    def end_log(request_log_entry, response_env)
      response_env.body = JSON.parse(response_env.body) if @parse_json
      request_log_entry[:response] = get_response_for_logs(response_env)
      request_log_entry[:status] = response_env.status
      request_log_entry[:finished] = Time.now
      request_log_entry[:elapsed_ms] = ((request_log_entry[:finished] - request_log_entry[:started]) * 1000).round(4)
    end

    def get_response_for_logs(response_env)
      @parse_json ? response_env.body.clone : response_env.body
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
