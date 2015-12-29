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
        json = @api.poll
        unless json.nil?
          json.each do |item|
            message = QQBot::Message.new
            value = item['value']
            case item['poll_type']
            when 'message' then
              message.type = 0
              message.from_id = value['from_uin']
              message.send_id = value['from_uin']
            when 'group_message' then
              message.type = 1
              message.from_id = value['from_uin']
              message.send_id = value['send_uin']
            when 'discu_message' then
              message.type = 2
              message.from_id = value['from_uin']
              message.send_id = value['send_uin']
            else
              message.type = 3
            end
            message.time = value['time']
            message.content = value['content'][1]

            font = QQBot::Font.new
            font_json = value['content'][0][1]
            font.color = font_json['color']
            font.name = font_json['name']
            font.size = font_json['size']
            font.style = font_json['style']
            message.font = font

            block.call message
          end
        end
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
          group_map[group.id] = group
        end

        gmarklist = json['gmarklist']
        gmarklist.each do |item|
          group_map[item['uin']].markname = item['markname']
        end

        return group_map.values
      end
    end

    def get_friend_list_with_category
      json = @api.nil? ? nil : @api.get_friend_list

      unless json.nil?
        category_list = []
        friend_list = build_friend_list json

        categories = json['categories']
        has_default_category = false
        categories.each do |item|
          category = QQBot::Category.new
          category.name = item['name']
          category.sort = item['sort']
          category.id = item['index']
          category.friends = friend_list.select { |friend| friend.category_id == category.id }
          category_list << category
          has_default_category ||= (category.id == 0)
        end

        unless has_default_category
          category = QQBot::Category.new
          category.name = '我的好友（默认）'
          category.sort = 1
          category.id = 0
          category.friends = friend_list.select { |friend| friend.category_id == category.id }
          category_list << category
        end

        return category_list
      end
    end

    def get_friend_list
      json = @api.nil? ? nil : @api.get_friend_list

      unless json.nil?
        return build_friend_list json
      end
    end

    def build_friend_list(json)
      friend_map = {}

      friends = json['friends']
      friends.each do |item|
        friend = QQBot::Friend.new
        friend.id = item['uin']
        friend.category_id = item['categories']
        friend_map[friend.id] = friend
      end

      marknames = json['marknames']
      marknames.each do |item|
        friend_map[item['uin']].markname = item['markname']
      end

      vipinfo = json['vipinfo']
      vipinfo.each do |item|
        friend = friend_map[item['u']]
        friend.is_vip = item['is_vip']
        friend.vip_level = item['vip_level']
      end

      info = json['info']
      info.each do |item|
        friend_map[item['uin']].nickname = item['nick']
      end

      return friend_map.values
    end

    def get_discuss_list
      json = @api.nil? ? nil : @api.get_discuss_list

      unless json.nil?
        discuss_list = []

        dnamelist = json['dnamelist']
        dnamelist.each do |item|
          discuss = QQBot::Discuss.new
          discuss.name = item['name']
          discuss.id = item['did']
          discuss_list << discuss
        end

        return discuss_list
      end
    end

    def send_to_friend(friend_id, content)
      !@api.nil? && @api.send_to_friend(friend_id, content)
    end

    def send_to_group(group_id, content)
      !@api.nil? && @api.send_to_group(group_id, content)
    end

    def send_to_discuss(discuss_id, content)
      !@api.nil? && @api.send_to_discuss(discuss_id, content)
    end
  end
end
