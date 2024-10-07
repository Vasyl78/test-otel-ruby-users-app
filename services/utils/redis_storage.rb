# frozen_string_literal: true

require 'redis'

module Utils
  module RedisStorage
    class << self
      def set(namespace='users', uuid, value)
        key = [namespace, uuid].join
        str_value = value.to_json
        redis.set(key, str_value, ex: 180)
      end

      def get(namespace='users', uuid)
        key = [namespace, uuid].join
        data = redis.get(key)
        return unless data.is_a?(String)

        JSON.parse(data)
      end

      def flush
        redis.flushall
      end

      protected

      def redis
        @redis ||= Redis.new(url: ::Constants::REDIS_URL)
      end
    end
  end
end
