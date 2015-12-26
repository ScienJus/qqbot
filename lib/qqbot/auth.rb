require 'net/http'
require 'uri'
require 'json'
require "fileutils"
require 'openssl'
require 'logger'
require_relative 'cookie'


module QQBot
  class Auth
    @@logger = Logger.new(STDOUT)

    @@user_agent = 'Mozilla/5.0 (Windows NT 6.3; WOW64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/45.0.2454.101 Safari/537.36';

    def login
      get_qrcode

      url = ''

      until url.start_with? 'http' do
        sleep 5
        url = verify_qrcode
        get_qrcode if url == '-1'
      end

      get_ptwebqq url

      get_vfwebqq

      get_psessionid_and_uin

      puts "ptwebqq = #{@ptwebqq}"
      puts "vfwebqq = #{@vfwebqq}"
      puts "psessionid = #{@psessionid}"
      puts "uin = #{@uin}"
    end

    def get_qrcode
      @@logger.info '开始获取二维码'

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
        use_ssl: uri.scheme == 'https',
        verify_mode: OpenSSL::SSL::VERIFY_NONE) do |http|

        req = Net::HTTP::Get.new uri

        req.initialize_http_header(
          'User-Agent' => @@user_agent
        )

        res = http.request req

        if res.is_a? Net::HTTPSuccess

          @cookie = QQBot::Cookie.new

          @cookie.put res.get_fields('set-cookie')

          file_name = File.expand_path('qrcode.png', File.dirname(__FILE__));

          File.open(file_name, 'wb') do |file|
            file.write res.body
            file.close
          end

          @@logger.info "二维码已经保存在#{file_name}中"

          if @pid == nil
            @@logger.info '开启web服务进程'

            @pid = spawn "ruby -run -e httpd #{file_name} -p 9090"
          end

          @@logger.info '也可以通过访问 http://localhost:9090 查看二维码'
        end

      end
    end

    def verify_qrcode
      @@logger.info '等待扫描二维码'

      uri = URI('https://ssl.ptlogin2.qq.com/ptqrlogin');
      uri.query =
        URI.encode_www_form(
          webqq_type: 10,
          remember_uin: 1,
          login2qq: 1,
          aid: 501004106,
          u1: 'http://Fw.qq.com/proxy.html?login2qq=1&webqq_type=10',
          ptredirect: 0,
          ptlang: 2052,
          daid: 164,
          from_ui: 1,
          pttype: 1,
          dumy: '',
          fp: 'loginerroralert',
          action: '0-0-157510',
          mibao_css: 'm_webqq',
          t: 1,
          g: 1,
          js_type: 0,
          js_ver: 10143,
          login_sig: '',
          pt_randsalt: 0,
        )

      Net::HTTP.start(uri.host, uri.port,
        use_ssl: uri.scheme == 'https',
        verify_mode: OpenSSL::SSL::VERIFY_NONE) do |http|

        req = Net::HTTP::Get.new uri

        req.initialize_http_header(
          'User-Agent' => @@user_agent,
          'Cookie' => @cookie.to_s
        )

        res = http.request req

        if res.is_a? Net::HTTPSuccess

          @cookie.put res.get_fields('set-cookie')

          array = res.body.force_encoding("UTF-8").split("','");

          array.each do |result|
            if result.start_with? '二维码已失效'
              @@logger.info '二维码已失效，请重新获取'
              return '-1'
            elsif result.start_with? 'http'
              @@logger.info '认证成功'
              @@logger.info '关闭web服务进程'
              system "kill -9 #{@pid}"
              return result
            end
          end
          return '0'
        end
      end
    end

    def get_ptwebqq url
      @@logger.info '开始获取ptwebqq'

      uri = URI(url);

      Net::HTTP.start(uri.host, uri.port,
        use_ssl: uri.scheme == 'https',
        verify_mode: OpenSSL::SSL::VERIFY_NONE) do |http|

        req = Net::HTTP::Get.new uri

        req.initialize_http_header(
          'User-Agent' => @@user_agent,
          'Cookie' => @cookie.to_s,
          'Referer' => 'http://s.web2.qq.com/proxy.html?v=20130916001&callback=1&id=1'
        )

        res = http.request req

        if res.code == '302'
          @cookie.put res.get_fields('set-cookie')
          @ptwebqq = @cookie['ptwebqq']
        else
          @@logger.info '获取ptwebqq失败'
        end
      end
    end

    def get_vfwebqq
      @@logger.info '开始获取vfwebqq'

      uri = URI('http://s.web2.qq.com/api/getvfwebqq');

      uri.query =
        URI.encode_www_form(
          ptwebqq: @ptwebqq,
          clientid: 53999199,
          psessionid: '',
          t: 0.1,
        )

      Net::HTTP.start(uri.host, uri.port,
        use_ssl: uri.scheme == 'https',
        verify_mode: OpenSSL::SSL::VERIFY_NONE) do |http|

        req = Net::HTTP::Get.new uri

        req.initialize_http_header(
          'User-Agent' => @@user_agent,
          'Cookie' => @cookie.to_s,
          'Referer' => 'http://s.web2.qq.com/proxy.html?v=20130916001&callback=1&id=1'
        )

        res = http.request req

        if (res.is_a? Net::HTTPSuccess) && (json = JSON.parse(res.body)) && (json['retcode'] == 0)
          @cookie.put res.get_fields('set-cookie')
          @vfwebqq = json['result']['vfwebqq']
        else
          @@logger.info '获取vfwebqq失败'
        end

      end
    end

    def get_psessionid_and_uin
      @@logger.info '开始获取psessionid和uin'

      uri = URI('http://d1.web2.qq.com/channel/login2');

      r = JSON.generate(
        ptwebqq: @ptwebqq,
        clientid: 53999199,
        psessionid: '',
        status: 'online'
      )

      Net::HTTP.start(uri.host, uri.port,
        use_ssl: uri.scheme == 'https',
        verify_mode: OpenSSL::SSL::VERIFY_NONE) do |http|

        req = Net::HTTP::Post.new uri

        req.set_form_data(
          r: r
        )

        req.initialize_http_header(
          'User-Agent' => @@user_agent,
          'Cookie' => @cookie.to_s,
          'Referer' => 'http://d1.web2.qq.com/proxy.html?v=20151105001&callback=1&id=2',
          'Origin' => 'http://d1.web2.qq.com',
        )

        res = http.request req

        if (res.is_a? Net::HTTPSuccess) && (json = JSON.parse(res.body)) && (json['retcode'] == 0)
          @cookie.put res.get_fields('set-cookie')
          @uin = json['result']['uin']
          @psessionid = json['result']['psessionid']
        else
          @@logger.info '获取psessionid和uin失败'
        end

      end
    end
  end
end
