require 'net/http'
require 'uri'
require 'json'
require "fileutils"
require 'openssl'

class QQApi

  @@user_agent = 'Mozilla/5.0 (Windows NT 6.3; WOW64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/45.0.2454.101 Safari/537.36';

  def login
  end

  def getQRCode
    uri = URI('https://ssl.ptlogin2.qq.com/ptqrshow');

    uri.query =
      URI.encode_www_form(
        appid: 501004106,
        e: 0,
        l: :M,
        s: 5,
        d: 72,
        v: 4,
        t: 0.1,
      )

    Net::HTTP.start(uri.host, uri.port,
    use_ssl: uri.scheme == 'https', verify_mode: OpenSSL::SSL::VERIFY_NONE) do |http|
      req = Net::HTTP::Get.new(uri)

      # 方法1 通过initialize_http_header设置header
      req.initialize_http_header(
        'User-Agent' => @@user_agent
      )

      res = http.request req

      if res.is_a?(Net::HTTPSuccess)
        puts res.body

        File.open('D:/1.png', 'wb') do |file|
          file.write res.body
          file.close
        end
      end

    end
  end

end

api = QQApi.new

api.getQRCode
