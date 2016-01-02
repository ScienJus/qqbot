require 'json'

module QQBot
  class Bot
    def initialize
      @api = QQBot::Api.new
      @api.auth_options = login
    end

    def self.check_response_json(code, body)
      if code == '200'
        json = JSON.parse body
        if json['retcode'] == 0
          return json['result']
        else
          QQBot::LOGGER.info "请求失败，JSON返回码 #{json['retcode']}"
        end
      else
        QQBot::LOGGER.info "请求失败，HTTP返回码 #{code}"
      end
    end

    def self.check_send_msg_response(code, body)
      if code == '200'
        json = JSON.parse body
        if json['errCode'] == 0
          QQBot::LOGGER.info '发送成功'
          return true
        else
          QQBot::LOGGER.info "发送失败，JSON返回码 #{json['retcode']}"
        end
      else
        QQBot::LOGGER.info "请求失败，HTTP返回码 #{code}"
      end
    end

    def get_qrcode
      code, body = @api.get_qrcode

      if code == '200'
        file_name = File.expand_path('qrcode.png', File.dirname(__FILE__));

        File.open(file_name, 'wb') do |file|
          file.write body
          file.close
        end

        QQBot::LOGGER.info "二维码已经保存在#{file_name}中"

        unless @pid
          QQBot::LOGGER.info '开启web服务进程'
          @pid = spawn("ruby -run -e httpd #{file_name} -p 9090")
        end

        QQBot::LOGGER.info '也可以通过访问 http://localhost:9090 查看二维码'
        return true
      else
        QQBot::LOGGER.info "请求失败，返回码#{code}"
      end
    end

    def verify_qrcode
      url = ''

      until url.start_with? 'http' do
        sleep 5
        code, body = @api.verify_qrcode

        if code == '200'
          result = body.force_encoding("UTF-8")
          if result.include? '二维码已失效'
            QQBot::LOGGER.info '二维码已失效，准备重新获取'
            return unless get_qrcode
          elsif result.include? 'http'
            QQBot::LOGGER.info '认证成功'
            return URI.extract(result).first
          end
        else
          QQBot::LOGGER.info "请求失败，返回码#{code}"
          return
        end
      end
    end

    def close_qrcode_server
      if @pid
        QQBot::LOGGER.info '关闭web服务进程'
        Process.kill('KILL', @pid)
        @pid = nil
      end
    end

    def get_ptwebqq(url)
      code, ptwebqq = @api.get_ptwebqq url

      if code == '302'
        ptwebqq
      else
        QQBot::LOGGER.info "请求失败，返回码#{code}"
      end
    end

    def get_vfwebqq(ptwebqq)
      code, body = @api.get_vfwebqq(ptwebqq)

      result = self.class.check_response_json(code, body)
      result['vfwebqq'] if result
    end

    def get_psessionid_and_uin(ptwebqq)
      code, body = @api.get_psessionid_and_uin ptwebqq

      result = self.class.check_response_json(code, body)
      if result
        return result['psessionid'], result['uin']
      end
    end

    def login
      QQBot::LOGGER.info '开始获取二维码'
      raise QQBot::Error::LoginFailed unless get_qrcode

      QQBot::LOGGER.info '等待扫描二维码'
      url = verify_qrcode
      raise QQBot::Error::LoginFailed unless url

      close_qrcode_server

      QQBot::LOGGER.info '开始获取ptwebqq'
      ptwebqq = get_ptwebqq url
      raise QQBot::Error::LoginFailed unless ptwebqq

      QQBot::LOGGER.info '开始获取vfwebqq'
      vfwebqq = get_vfwebqq ptwebqq
      raise QQBot::Error::LoginFailed unless vfwebqq

      QQBot::LOGGER.info '开始获取psessionid和uin'
      psessionid, uin = get_psessionid_and_uin ptwebqq
      raise QQBot::Error::LoginFailed unless uin && psessionid

      {
        ptwebqq: ptwebqq,
        vfwebqq: vfwebqq,
        psessionid: psessionid,
        uin: uin
      }
    end

    def poll
      loop do
        code, body = @api.poll
        result = self.class.check_response_json(code, body)

        if result
          result.each do |item|
            message = QQBot::Message.new
            value = item['value']
            message.type, message.from_id, message.send_id =
            case item['poll_type']
            when 'message' then [0, value['from_uin'], value['from_uin']]
            when 'group_message' then [1, value['from_uin'], value['send_uin']]
            when 'discu_message' then [2, value['from_uin'], value['send_uin']]
            else 3
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

            yield message if block_given?
          end
        end
        sleep 1
      end
    end

    def get_group_list
      code, body = @api.get_group_list
      result = self.class.check_response_json(code, body)

      if result
        group_map = {}

        gnamelist = result['gnamelist']
        gnamelist.each do |item|
          group = QQBot::Group.new
          group.name = item['name']
          group.id = item['gid']
          group.code = item['code']
          group_map[group.id] = group
        end

        gmarklist = result['gmarklist']
        gmarklist.each do |item|
          group_map[item['uin']].markname = item['markname']
        end

        group_map.values
      end
    end

    def get_friend_list_with_category
      code, body = @api.get_friend_list
      result = self.class.check_response_json(code, body)

      if result
        friend_list = self.class.build_friend_list result

        categories = result['categories']
        has_default_category = false
        category_list = categories.collect do |item|
          category = QQBot::Category.new
          category.name = item['name']
          category.sort = item['sort']
          category.id = item['index']
          category.friends = friend_list.select { |friend| friend.category_id == category.id }
          has_default_category ||= (category.id == 0)
          category
        end

        unless has_default_category
          category = QQBot::Category.new
          category.name = '我的好友（默认）'
          category.sort = 1
          category.id = 0
          category.friends = friend_list.select { |friend| friend.category_id == category.id }
          category_list << category
        end

        category_list
      end
    end

    def get_friend_list
      code, body = @api.get_friend_list
      result = self.class.check_response_json(code, body)

      if result
        self.class.build_friend_list(result)
      end
    end

    def self.build_friend_list(json)
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

      friend_map.values
    end

    def get_discuss_list
      code, body = @api.get_discuss_list
      result = self.class.check_response_json(code, body)

      if result
        dnamelist = result['dnamelist']
        dnamelist.collect do |item|
          discuss = QQBot::Discuss.new
          discuss.name = item['name']
          discuss.id = item['did']
          discuss
        end
      end
    end

    def send_to_friend(friend_id, content)
      code, body = @api.send_to_friend(friend_id, content)
      self.class.check_send_msg_response(code, body)
    end

    def send_to_group(group_id, content)
      code, body = @api.send_to_group(group_id, content)
      self.class.check_send_msg_response(code, body)
    end

    def send_to_discuss(discuss_id, content)
      code, body = @api.send_to_discuss(discuss_id, content)
      self.class.check_send_msg_response(code, body)
    end

    def send_to_sess(sess_id, content)
      code, body = @api.send_to_sess(sess_id, content)
      self.class.check_send_msg_response(code, body)
    end

    def get_account_info
      code, body = @api.get_account_info
      result = self.class.check_response_json(code, body)

      if result
        # TODO
        build_user_info(result)
      end
    end

    def get_friend_info(friend_id)
      code, body = @api.get_friend_info(friend_id)
      result = self.class.check_response_json(code, body)

      if result
        # TODO
        build_user_info(result)
      end
    end

    def build_user_info(result)
      user_info = QQBot::UserInfo.new
      user_info.phone = result['phone']
      user_info.occupation = result['occupation']
      user_info.college = result['college']
      user_info.id = result['uin']
      user_info.blood = result['blood']
      user_info.slogan = result['lnick']
      user_info.homepage = result['homepage']
      user_info.vip_info = result['vip_info']
      user_info.city = result['city']
      user_info.country = result['country']
      user_info.province = result['province']
      user_info.personal = result['personal']
      user_info.shengxiao = result['shengxiao']
      user_info.nickname = result['nick']
      user_info.email = result['email']
      user_info.account = result['account']
      user_info.gender = result['gender']
      user_info.mobile = result['mobile']
      birthday = QQBot::Birthday.new
      birthday.year = result['birthday']['year']
      birthday.month = result['birthday']['month']
      birthday.day = result['birthday']['day']
      user_info.birthday = birthday

      user_info
    end

    def get_recent_list
      code, body = @api.get_recent_list
      result = self.class.check_response_json(code, body)

      if result
        result.collect do |item|
          recent = QQBot::Recent.new
          recent.id = item['uin']
          recent.type = item['type']
          recent
        end
      end
    end

    def get_qq_by_id(id)
      code, body = @api.get_qq_by_id(id)
      result = self.class.check_response_json(code, body)

      if result
        result['account']
      end
    end

    def get_online_friends
      code, body = @api.get_online_friends
      result = self.class.check_response_json(code, body)

      if result
        result.collect do |item|
          online = QQBot::Online.new
          online.id = item['uin']
          online.client_type = item['client_type']
          online
        end
      end
    end

    def get_group_info(group_code)
      code, body = @api.get_group_info(group_code)
      result = self.class.check_response_json(code, body)

      if result
        group_info = QQBot::GroupInfo.new
        ginfo = result['ginfo']
        group_info.id = ginfo['gid']
        group_info.create_time = ginfo['createtime']
        group_info.memo = ginfo['memo']
        group_info.name = ginfo['name']
        group_info.owner_id = ginfo['owner']
        group_info.markname = ginfo['markname']

        member_map = {}

        minfo = result['minfo']
        minfo.each do |item|
          member = QQBot::GroupMember.new
          member.id = item['uin']
          member.nickname = item['nick']
          member.gender = item['gender']
          member.country = item['country']
          member.city = item['city']
          member_map[member.id] = member
        end

        cards = result['cards']
        cards.each { |item| member_map[item['muin']].markname = item['card'] } if cards

        vipinfo = result['vipinfo']
        vipinfo.each do |item|
          member = member_map[item['u']]
          member.is_vip = item['is_vip']
          member.vip_level = item['vip_level']
        end

        stats = result['stats']
        stats.each do |item|
          member = member_map[item['uin']]
          member.client_type = item['client_type']
          member.status = item['stat']
        end

        group_info.members = member_map.values

        group_info
      end
    end

    def get_discuss_info(discuss_id)
      code, body = @api.get_discuss_info(discuss_id)
      result = self.class.check_response_json(code, body)

      if result
        discuss_info = QQBot::DiscussInfo.new
        info = result['info']
        discuss_info.id = info['did']
        discuss_info.name = info['discu_name']

        member_map = {}

        mem_info = result['mem_info']
        mem_info.each do |item|
          member = QQBot::DiscussMember.new
          member.id = item['uin']
          member.nickname = item['nick']
          member_map[member.id] = member
        end

        mem_status = result['mem_status']
        mem_status.each do |item|
          member = member_map[item['uin']]
          member.client_type = item['client_type']
          member.status = item['status']
        end

        discuss_info.members = member_map.values

        discuss_info
      end
    end
  end
end
