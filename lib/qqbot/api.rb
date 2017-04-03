require 'uri'

module QQBot
  class Api

    def initialize
      @client = QQBot::Client.new
      @msg_id = 1_000_000
    end

    def auth_options=(options = {})
      @options = options
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
      @client.get(uri)
    end

    # webqq 对应js源码 https://imgcache.qq.com/ptlogin/ver/10203/js/mq_comm.js
    def verify_qrcode
      uri = URI('https://ssl.ptlogin2.qq.com/ptqrlogin');
      uri.query =
        URI.encode_www_form(
          ptqrtoken: get_ptqrtoken,
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
          # action: '0-0-157510',
          action: '0-0-12038',
          mibao_css: 'm_webqq',
          t: 1,
          g: 1,
          js_type: 0,
          # js_ver: 10143,
          js_ver: 10203,
          login_sig: '',
          pt_randsalt: 2,
        )
      @client.get(uri)
    end

    def get_ptqrtoken
      t = @client.cookie['qrsig']
      e = 0
      i = 0
      n = t.length

      while n > i do
        e += (e << 5) + t[i].ord
        i += 1
      end

      return 2147483647 & e
    end

    def get_ptwebqq(url)
      uri = URI(url);
      code, body = @client.get(uri, 'http://s.web2.qq.com/proxy.html?v=20130916001&callback=1&id=1')
      return code, @client.get_cookie('ptwebqq')
    end

    def get_vfwebqq(ptwebqq)
      uri = URI('http://s.web2.qq.com/api/getvfwebqq');
      uri.query =
        URI.encode_www_form(
          ptwebqq: ptwebqq,
          clientid: QQBot::CLIENT_ID,
          psessionid: '',
          t: 0.1,
        )
      @client.get(uri, 'http://s.web2.qq.com/proxy.html?v=20130916001&callback=1&id=1')
    end

    def get_psessionid_and_uin(ptwebqq)
      uri = URI('http://d1.web2.qq.com/channel/login2');
      r = JSON.generate(
        ptwebqq: ptwebqq,
        clientid: QQBot::CLIENT_ID,
        psessionid: '',
        status: 'online'
      )
      @client.post(uri, 'http://d1.web2.qq.com/proxy.html?v=20151105001&callback=1&id=2', r: r)
    end

    def self.hash(uin, ptwebqq)
      n = Array.new(4, 0)
      ptwebqq.chars.each_index { |i| n[i % 4] ^= ptwebqq[i].ord }
      u = ['EC', 'OK']
      v = Array.new(4)
      v[0] = uin >> 24 & 255 ^ u[0][0].ord;
      v[1] = uin >> 16 & 255 ^ u[0][1].ord;
      v[2] = uin >> 8 & 255 ^ u[1][0].ord;
      v[3] = uin & 255 ^ u[1][1].ord;
      u = Array.new(8)
      (0...8).each { |i| u[i] = i.odd? ? v[i >> 1] : n[i >> 1] }
      n = ['0', '1', '2', '3', '4', '5', '6', '7', '8', '9', 'A', 'B', 'C', 'D', 'E', 'F']
      v = ''
      u.each do |i|
        v << n[(i >> 4) & 15]
        v << n[i & 15]
      end
      v
    end

    def poll
      uri = URI('http://d1.web2.qq.com/channel/poll2')
      r = JSON.generate(
        ptwebqq: @options[:ptwebqq],
        clientid: QQBot::CLIENT_ID,
        psessionid: @options[:psessionid],
        key: ''
      )
      begin
        @client.post(uri, 'http://d1.web2.qq.com/proxy.html?v=20151105001&callback=1&id=2', r: r)
      rescue
        retry
      end
    end

    def get_group_list
        uri = URI('http://s.web2.qq.com/api/get_group_name_list_mask2')
        r = JSON.generate(
          vfwebqq: @options[:vfwebqq],
          hash: hash
        )
        @client.post(uri, 'http://d1.web2.qq.com/proxy.html?v=20151105001&callback=1&id=2', r: r)
    end

    def hash
      self.class.hash(@options[:uin], @options[:ptwebqq])
    end

    def get_friend_list
        uri = URI('http://s.web2.qq.com/api/get_user_friends2')
        r = JSON.generate(
          vfwebqq: @options[:vfwebqq],
          hash: hash
        )
        @client.post(uri, 'http://s.web2.qq.com/proxy.html?v=20130916001&callback=1&id=1', r: r)
    end

    def get_discuss_list
        uri = URI('http://s.web2.qq.com/api/get_discus_list')
        uri.query =
          URI.encode_www_form(
            clientid: QQBot::CLIENT_ID,
            psessionid: @options[:psessionid],
            vfwebqq: @options[:vfwebqq],
            t: 0.1
          )
        @client.get(uri, 'http://d1.web2.qq.com/proxy.html?v=20151105001&callback=1&id=2')
    end

    def send_to_friend(friend_id, content)
      uri = URI('http://d1.web2.qq.com/channel/send_buddy_msg2')
      r = JSON.generate(
        to: friend_id,
        content: self.class.build_message(content),
        face: 522,
        clientid: QQBot::CLIENT_ID,
        msg_id: msg_id,
        psessionid: @options[:psessionid]
      )
      @client.post(uri, 'http://d1.web2.qq.com/proxy.html?v=20151105001&callback=1&id=2', r: r)
    end

    def send_to_group(group_id, content)
      uri = URI('http://d1.web2.qq.com/channel/send_qun_msg2')
      r = JSON.generate(
        group_uin: group_id,
        content: self.class.build_message(content),
        face: 522,
        clientid: QQBot::CLIENT_ID,
        msg_id: msg_id,
        psessionid: @options[:psessionid]
      )
      @client.post(uri, 'http://d1.web2.qq.com/proxy.html?v=20151105001&callback=1&id=2', r: r)
    end

    def send_to_discuss(discuss_id, content)
      uri = URI('http://d1.web2.qq.com/channel/send_discu_msg2')
      r = JSON.generate(
        did: discuss_id,
        content: self.class.build_message(content),
        face: 522,
        clientid: QQBot::CLIENT_ID,
        msg_id: msg_id,
        psessionid: @options[:psessionid]
      )
      @client.post(uri, 'http://d1.web2.qq.com/proxy.html?v=20151105001&callback=1&id=2', r: r)
    end

    def send_to_sess(sess_id, content)
      uri = URI('http://d1.web2.qq.com/channel/send_sess_msg2')
      r = JSON.generate(
        to: sess_id,
        content: self.class.build_message(content),
        face: 522,
        clientid: QQBot::CLIENT_ID,
        msg_id: msg_id,
        psessionid: @options[:psessionid]
      )
      @client.post(uri, 'http://d1.web2.qq.com/proxy.html?v=20151105001&callback=1&id=2', r: r)
    end

    def get_account_info
      uri = URI('http://s.web2.qq.com/api/get_self_info2')
      uri.query =
        URI.encode_www_form(
          t: 0.1
        )

      @client.get(uri, 'http://s.web2.qq.com/proxy.html?v=20130916001&callback=1&id=1')
    end

    def get_recent_list
      uri = URI('http://d1.web2.qq.com/channel/get_recent_list2')
      r = JSON.generate(
        vfwebqq: @options[:vfwebqq],
        clientid: QQBot::CLIENT_ID,
        psessionid: ''
      )
      @client.post(uri, 'http://d1.web2.qq.com/proxy.html?v=20151105001&callback=1&id=2', r: r)
    end

    def get_qq_by_id(id)
      uri = URI('http://s.web2.qq.com/api/get_friend_uin2')
      uri.query =
        URI.encode_www_form(
          tuin: id,
          type: 1,
          vfwebqq: @options[:vfwebqq],
          t: 0.1
        )
      @client.get(uri, 'http://s.web2.qq.com/proxy.html?v=20130916001&callback=1&id=1')
    end

    def get_online_friends
      uri = URI('http://d1.web2.qq.com/channel/get_online_buddies2')
      uri.query =
        URI.encode_www_form(
          vfwebqq: @options[:vfwebqq],
          clientid: QQBot::CLIENT_ID,
          psessionid: @options[:psessionid],
          t: 0.1
        )
      @client.get(uri, 'http://d1.web2.qq.com/proxy.html?v=20151105001&callback=1&id=2')
    end

    def get_group_info(group_code)
      uri = URI('http://s.web2.qq.com/api/get_group_info_ext2')
      uri.query =
        URI.encode_www_form(
          gcode: group_code,
          vfwebqq: @options[:vfwebqq],
          t: 0.1
        )
      @client.get(uri, 'http://s.web2.qq.com/proxy.html?v=20130916001&callback=1&id=1')
    end

    def get_discuss_info(discuss_id)
      uri = URI('http://d1.web2.qq.com/channel/get_discu_info')
      uri.query =
        URI.encode_www_form(
          did: discuss_id,
          vfwebqq: @options[:vfwebqq],
          clientid: QQBot::CLIENT_ID,
          psessionid: @options[:psessionid],
          t: 0.1
        )
      @client.get(uri, 'http://d1.web2.qq.com/proxy.html?v=20151105001&callback=1&id=2')
    end

    def get_friend_info(friend_id)
      uri = URI('http://s.web2.qq.com/api/get_friend_info2')
      uri.query =
        URI.encode_www_form(
          tuin: friend_id,
          vfwebqq: @options[:vfwebqq],
          clientid: QQBot::CLIENT_ID,
          psessionid: @options[:psessionid],
          t: 0.1
        )
      @client.get(uri, 'http://s.web2.qq.com/proxy.html?v=20130916001&callback=1&id=1')
    end

    def hash
      self.class.hash(@options[:uin], @options[:ptwebqq])
    end

    def msg_id
      @msg_id += 1
    end

    def self.build_message(content)
      JSON.generate(
        [
            content.force_encoding("UTF-8"),
            [
                'font',
                {
                    name: '宋体',
                    size: 10,
                    style: [0, 0, 0],
                    color: '000000'
                }
            ]
        ]
      )
    end
  end
end
