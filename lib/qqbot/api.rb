require 'uri'
require 'json'
require 'fileutils'

module QQBot
  class Api

    def initialize(client, options = {})
      @client = client
      @options = options
    end

    def self.hash(uin, ptwebqq)
      n = Array.new(4, 0)

      for i in (0...ptwebqq.size)
        n[i % 4] ^= ptwebqq[i].ord
      end

      u = ['EC', 'OK']

      v = Array.new(4)
      v[0] = uin >> 24 & 255 ^ u[0][0].ord;
      v[1] = uin >> 16 & 255 ^ u[0][1].ord;
      v[2] = uin >> 8 & 255 ^ u[1][0].ord;
      v[3] = uin & 255 ^ u[1][1].ord;

      u = Array.new(8)
      for i in (0...8)
        u[i] = i.odd? ? v[i >> 1] : n[i >> 1]
      end

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
        clientid: 53999199,
        psessionid: @options[:psessionid],
        key: ''
      )

      begin
        code, body = @client.post(uri, 'http://d1.web2.qq.com/proxy.html?v=20151105001&callback=1&id=2', r: r)
      rescue
        retry
      end

      if code == '200'
        json = JSON.parse body
        if json['retcode'] == 0
          return json['result']
        else
          QQBot::LOGGER.info "获取消息失败 返回码 #{json['retcode']}"
        end
      else
        QQBot::LOGGER.info "请求失败，返回码#{code}"
      end
    end

    def get_group_list
        uri = URI('http://s.web2.qq.com/api/get_group_name_list_mask2')

        r = JSON.generate(
          vfwebqq: @options[:vfwebqq],
          hash: hash
        )

        code, body = @client.post(uri, 'http://d1.web2.qq.com/proxy.html?v=20151105001&callback=1&id=2', r: r)

        if code == '200'
          json = JSON.parse body
          if json['retcode'] == 0
            return json['result']
          else
            QQBot::LOGGER.info "获取群列表失败 返回码 #{json['retcode']}"
          end
        else
          QQBot::LOGGER.info "请求失败，返回码#{code}"
        end
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

        code, body = @client.post(uri, 'http://s.web2.qq.com/proxy.html?v=20130916001&callback=1&id=1', r: r)

        if code == '200'
          json = JSON.parse body
          if json['retcode'] == 0
            return json['result']
          else
            QQBot::LOGGER.info "获取群列表失败 返回码 #{json['retcode']}"
          end
        else
          QQBot::LOGGER.info "请求失败，返回码#{code}"
        end
    end

    def hash
      self.class.hash(@options[:uin], @options[:ptwebqq])
    end
  end
end
