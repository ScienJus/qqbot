require 'uri'
require 'json'
require "fileutils"
require 'logger'

module QQBot
  class Api

    def initialize(client, options = {})
      @client = client
      @options = options
    end

    def poll
      uri = URI('http://d1.web2.qq.com/channel/poll2')

      r = JSON.generate(
        ptwebqq: @options['ptwebqq'],
        clientid: 53999199,
        psessionid: @options['psessionid'],
        key: ''
      )

      code, body = @client.post(uri, 'http://d1.web2.qq.com/proxy.html?v=20151105001&callback=1&id=2', r: r)

      if code == '200'
        json = JSON.parse body
        if json['retcode'] == 0
          return json['result']
        else
          @@logger.info "获取消息失败 返回码 #{json['retcode']}"
        end
      else
        @@logger.info "请求失败，返回码#{code}"
      end

    end
  end
end
