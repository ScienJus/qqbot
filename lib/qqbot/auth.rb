require 'uri'
require 'json'
require 'fileutils'

module QQBot
  class Auth

    def initialize client
      @client = client
    end

    def get_qrcode
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

      @client.get uri
    end

    def verify_qrcode
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

      @client.get uri
    end

    def get_ptwebqq(url)
      uri = URI(url);

      @client.get(uri, 'http://s.web2.qq.com/proxy.html?v=20130916001&callback=1&id=1')
    end

    def get_vfwebqq(ptwebqq)
      uri = URI('http://s.web2.qq.com/api/getvfwebqq');

      uri.query =
        URI.encode_www_form(
          ptwebqq: ptwebqq,
          clientid: 53999199,
          psessionid: '',
          t: 0.1,
        )

      @client.get(uri, 'http://s.web2.qq.com/proxy.html?v=20130916001&callback=1&id=1')
    end

    def get_psessionid_and_uin(ptwebqq)
      uri = URI('http://d1.web2.qq.com/channel/login2');

      r = JSON.generate(
        ptwebqq: ptwebqq,
        clientid: 53999199,
        psessionid: '',
        status: 'online'
      )

      @client.post(uri, 'http://d1.web2.qq.com/proxy.html?v=20151105001&callback=1&id=2', r: r)
    end
  end
end
