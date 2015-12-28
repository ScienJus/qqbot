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
end
