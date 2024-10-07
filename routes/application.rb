# frozen_string_literal: true

module Routes
  # Routes::Application
  class Application < ::Roda
    opts[:root] = ENV.fetch('APP_ROOT', nil)
    plugin :all_verbs
    plugin :symbol_status
    plugin :json, content_type: 'application/vnd.api+json'
    plugin :json_parser
    plugin :slash_path_empty
    plugin :hash_routes
    plugin :request_headers

    use Middlewares::RackMiddleware

    route do |req|
      req.is('users', String, method: :get) do |uuid|
        user_data = Utils::RedisStorage.get(uuid)

        unless user_data.is_a?(Hash)
          user_data = {
            uuid:        uuid,
            first_name:  FFaker::Name.first_name,
            last_name:   FFaker::Name.last_name,
            gender:      FFaker::Identification.gender,
            passport_no: FFaker::Identification.ssn
          }

          Utils::RedisStorage.set(uuid, user_data)
        end

        user_address = Utils::JsonRequest.call(
          url: format(Constants::ADDRESSES_GET_BY_UUID_URL, { :uuid => uuid }),
          payload: {},
          http_method: :get
        )

        user_data['address'] = user_address

        response.status = 200
        user_data
      end
    end
  end
end
