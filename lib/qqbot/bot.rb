module QQBot
  class Bot
    def initialize
      @client = QQBot::Client.new
      @auth = QQBot::Auth.new @client
    end

    def login
      @auth.get_qrcode

      url = ''

      until url.start_with? 'http' do
        sleep 5
        url = @auth.verify_qrcode
        @auth.get_qrcode if url == '-1'
      end

      @auth.get_ptwebqq url

      @auth.get_vfwebqq

      @auth.get_psessionid_and_uin

      auth_options = @auth.options

      @api = QQBot::Api.new(@client, auth_options)
    end

    def poll &block
      return if @api.nil?

      loop do
        block.call @api.poll
        sleep 1
      end
    end

    def get_group_list
      json = @api.nil? ? nil : @api.get_group_list

      unless json.nil?
        group_map = {}

        gnamelist = json['gnamelist']
        gnamelist.each do |item|
          group = QQBot::Group.new
          group.name = item['name']
          group.id = item['gid']
          group.code = item['code']
          grou_map[group.id] = group
        end

        gmarklist = json['gmarklist']
        gmarklist.each do |item|
          group_map[item[uin]].markname = item['markname']
        end
        
        return group_map.values
      end
    end
  end

end
