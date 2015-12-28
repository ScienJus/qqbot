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
end
