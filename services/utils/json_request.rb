# frozen_string_literal: true

module Utils
  class JsonRequest
    class << self
      def call(*args, **kwargs)
        new(*args, **kwargs).execute
      end
    end

    def initialize(url:, payload:, http_method:)
      @url = url
      @payload = payload
      @http_method = http_method
      initialize_connection
    end

    def execute
      response = connection.public_send(http_method) do |request|
        request.body = payload
      end

      response.body
    end

    private

    attr_reader :url,
                :payload,
                :http_method,
                :connection

    def initialize_connection
      @connection = Faraday.new(url: url, headers: default_headers, ssl: false) do |c|
        c.request :json
        c.response :json
      end
    end

    def default_headers
      { 'Content-Type' => 'application/json' }
    end
  end
end
