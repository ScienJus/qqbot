require 'net/http'
require 'openssl'

module QQBot
  class Client

    @@user_agent = 'Mozilla/5.0 (Windows NT 6.3; WOW64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/45.0.2454.101 Safari/537.36'

    attr_accessor :cookie

    def self.origin(uri)
      "#{uri.scheme}://#{uri.host}"
    end

    def initialize
      @cookie = QQBot::Cookie.new
    end

    def get(uri, referer = '')
      QQBot::LOGGER.debug { "get #{uri.to_s}" }

      Net::HTTP.start(uri.host, uri.port,
        use_ssl: uri.scheme == 'https',
        verify_mode: OpenSSL::SSL::VERIFY_NONE) do |http|
        req = Net::HTTP::Get.new(uri)
        req.initialize_http_header(
          'User-Agent' => @@user_agent,
          'Cookie' => @cookie.to_s,
          'Referer' => referer
        )
        res = http.request(req)
        @cookie.put(res.get_fields('set-cookie'))
        QQBot::LOGGER.debug { "code: #{res.code}, body: #{res.body}" }
        return res.code, res.body
      end
    end

    def post(uri, referer = '', form_data = {})
      QQBot::LOGGER.debug { "post uri: #{uri.to_s} data: #{form_data.to_s}" }
      Net::HTTP.start(uri.host, uri.port,
        use_ssl: uri.scheme == 'https',
        verify_mode: OpenSSL::SSL::VERIFY_NONE) do |http|
        req = Net::HTTP::Post.new(uri)
        req.set_form_data(form_data)
        req.initialize_http_header(
          'User-Agent' => @@user_agent,
          'Cookie' => @cookie.to_s,
          'Referer' => referer,
          'Origin' => self.class.origin(uri)
        )
        res = http.request(req)
        @cookie.put(res.get_fields('set-cookie'))
        QQBot::LOGGER.debug { "response code: #{res.code}, body: #{res.body}" }
        return res.code, res.body
      end
    end

    def get_cookie(key)
      @cookie[key]
    end
  end
end
