require 'faraday'
FEDEX_URL = 'https://apis-sandbox.fedex.com'

module FedexRatesGem
  module Connection
    class << self
      def connection(credentials, data)
        @credentials = credentials

        conn = Faraday.new(url: FEDEX_URL) do |faraday|
          faraday.request :json
          faraday.response :json, content_type: /\bjson$/
          faraday.adapter Faraday.default_adapter
        end
        @access_token = get_access_token

        return @access_token if @access_token['status'] != 200
        body = request_body(credentials, data)
        response = conn.post('/rate/v1/rates/quotes', body, headers)
        result = response.body
      end

      private

      def get_access_token
        conn = Faraday.new(url: FEDEX_URL) do |faraday|
          faraday.request :url_encoded
          faraday.adapter Faraday.default_adapter
        end
        response = conn.post '/oauth/token', generate_query_params

        if response.success?
          {
            status: response.status,
            access_token: JSON.parse(response.body)['access_token']
          }
        else
          {
            status: response.status,
            error: JSON.parse(response.body)['errors'].first['message']
          }
        end
      end

      def generate_query_params
        {
          grant_type: 'client_credentials',
          client_id: @credentials[:key],
          client_secret: @credentials[:password],
        }
      end

      def headers
        {
          'Authorization' => "Bearer #{@access_token['access_token']}",
          'Content-Type' => 'application/json',
          'X-locale': "en_US"
        }
      end

      def request_body(credentials, data)
        {
          key: credentials[:key],
          password: credentials[:password],
          account_number: credentials[:account_number],
          meter_number: credentials[:meter_number],
          packages: {
            weight: {
              value: data['packages']['weight']['value'],
              units: data['packages']['weight']['units']
            },
            dimensions: {
              length: data['packages']['dimensions']['length'],
              width: data['packages']['dimensions']['width'],
              height: data['packages']['dimensions']['height'],
              units: data['packages']['dimensions']['units']
            }
          },
          shipper: {
            postalCode: data['shipper']['postalCode'],
            country_code: data['shipper']['country_code']
          },
          recipient: {
            postalCode: data['recipient']['postalCode'],
            country_code: data['recipient']['country_code']
          }
        }
      end
    end
  end
end