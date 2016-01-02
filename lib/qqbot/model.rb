module QQBot
  class Group
    attr_accessor :name, :code, :id, :markname
  end

  class Friend
    attr_accessor :nickname, :category_id, :id, :is_vip, :vip_level, :markname
  end

  class Category
    attr_accessor :name, :sort, :id, :friends
  end

  class Discuss
    attr_accessor :name, :id
  end

  class Message
    attr_accessor :type, :from_id, :send_id, :time, :content, :font
  end

  class Font
    attr_accessor :color, :name, :size, :style
  end

  class UserInfo
    attr_accessor :phone, :occupation, :college, :id, :blood, :slogan, :homepage, :vip_info, :city, :country, :province, :personal, :shengxiao, :nickname, :email, :account, :gender, :mobile, :birthday
  end

  class Birthday
    attr_accessor :year, :month, :day
  end

  class Recent
    attr_accessor :id, :type
  end

  class Online
    attr_accessor :id, :client_type
  end

  class GroupMember
    attr_accessor :id, :nickname, :gender, :country, :city, :markname, :is_vip, :vip_level, :client_type, :status
  end

  class GroupInfo
    attr_accessor :id, :create_time, :memo, :name, :owner_id, :markname, :members
  end

  class DiscussInfo
    attr_accessor :id, :name, :members
  end

  class DiscussMember
    attr_accessor :id, :nickname, :client_type, :status
  end
end
