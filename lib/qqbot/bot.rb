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
          group_map[group.id] = group
        end

        gmarklist = json['gmarklist']
        gmarklist.each do |item|
          group_map[item['uin']].markname = item['markname']
        end

        return group_map.values
      end
    end

    def get_friend_list
      json = @api.nil? ? nil : @api.get_friend_list

      unless json.nil?
        friend_map = {}
        category_list = []

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

        categories = json['categories']
        has_default_category = false
        categories.each do |item|
          category = QQBot::Category.new
          category.name = item['name']
          category.sort = item['sort']
          category.id = item['index']
          category.friends = friend_map.values.select { |friend| friend.category_id == category.id }
          category_list << category
          has_default_category ||= (category.id == 0)
        end

        unless has_default_category
          category = QQBot::Category.new
          category.name = '我的好友（默认）'
          category.sort = 1
          category.id = 0
          category.friends = friend_map.values.select { |friend| friend.category_id == category.id }
          category_list << category
        end

        return category_list
      end
    end
  end
end
