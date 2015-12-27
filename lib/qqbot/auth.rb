require 'uri'
require 'json'
require "fileutils"

module QQBot
  class Auth

    def initialize client
      @client = client
    end

    def get_qrcode
      QQBot::LOGGER.info '开始获取二维码'

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

      code, body = @client.get uri

      if code == '200'
        file_name = File.expand_path('qrcode.png', File.dirname(__FILE__));

        File.open(file_name, 'wb') do |file|
          file.write body
          file.close
        end

        QQBot::LOGGER.info "二维码已经保存在#{file_name}中"

        if @pid == nil
          QQBot::LOGGER.info '开启web服务进程'

          @pid = spawn("ruby -run -e httpd #{file_name} -p 9090", out: '/dev/null')
        end

        QQBot::LOGGER.info '也可以通过访问 http://localhost:9090 查看二维码'
      else
        QQBot::LOGGER.info "请求失败，返回码#{code}"
      end
    end

    def verify_qrcode
      QQBot::LOGGER.info '等待扫描二维码'

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

      code, body = @client.get uri

      if code == '200'
        result = body.force_encoding("UTF-8")
        if result.include? '二维码已失效'
          QQBot::LOGGER.info '二维码已失效，请重新获取'
          return '-1'
        elsif result.include? 'http'
          QQBot::LOGGER.info '认证成功'
          unless @pid == nil
            QQBot::LOGGER.info '关闭web服务进程'
            system "kill -9 #{@pid}"
          end
          return URI.extract(result)[0]
        else
          return '0'
        end
      else
        QQBot::LOGGER.info "请求失败，返回码#{code}"
        return '0'
      end
    end

    def get_ptwebqq url
      QQBot::LOGGER.info '开始获取ptwebqq'

      uri = URI(url);

      code, body = @client.get(uri, 'http://s.web2.qq.com/proxy.html?v=20130916001&callback=1&id=1')

      if code == '302'
        @ptwebqq = @client.get_cookie :ptwebqq
      else
        QQBot::LOGGER.info "请求失败，返回码#{code}"
      end
    end

    def get_vfwebqq
      QQBot::LOGGER.info '开始获取vfwebqq'

      uri = URI('http://s.web2.qq.com/api/getvfwebqq');

      uri.query =
        URI.encode_www_form(
          ptwebqq: @ptwebqq,
          clientid: 53999199,
          psessionid: '',
          t: 0.1,
        )

      code, body = @client.get(uri, 'http://s.web2.qq.com/proxy.html?v=20130916001&callback=1&id=1')

      if code == '200'
        json = JSON.parse body
        if json['retcode'] == 0
          @vfwebqq = json['result']['vfwebqq']
        else
          QQBot::LOGGER.info "获取vfwebqq失败 返回码 #{json['retcode']}"
        end
      else
        QQBot::LOGGER.info "请求失败，返回码#{code}"
      end
    end

    def get_psessionid_and_uin
      QQBot::LOGGER.info '开始获取psessionid和uin'

      uri = URI('http://d1.web2.qq.com/channel/login2');

      r = JSON.generate(
        ptwebqq: @ptwebqq,
        clientid: 53999199,
        psessionid: '',
        status: 'online'
      )

      code, body = @client.post(uri, 'http://d1.web2.qq.com/proxy.html?v=20151105001&callback=1&id=2', r: r)

      if code == '200'
        json = JSON.parse body
        if json['retcode'] == 0
          @uin = json['result']['uin']
          @psessionid = json['result']['psessionid']
        else
          QQBot::LOGGER.info "获取vfwebqq失败 返回码 #{json['retcode']}"
        end
      else
        QQBot::LOGGER.info "请求失败，返回码#{code}"
      end
    end

    def options
      {
        ptwebqq: @ptwebqq,
        vfwebqq: @vfwebqq,
        psessionid: @psessionid,
        uin: @uin
      }
    end
  end
end
