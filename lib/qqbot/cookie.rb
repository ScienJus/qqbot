module QQBot
  class Cookie

    def put set_cookie_array
      return if set_cookie_array == nil
      @cookies = {} if @cookies == nil

      set_cookie_array.each do |set_cookie|
        set_cookie.split('; ').each do |cookie|
          k, v = cookie.split('=')
          @cookies[k] = v unless v == nil
        end
      end
    end

    def [] key
      return nil if @cookies == nil
      @cookies[key] || ''
    end

    def to_s
      return nil if @cookies == nil
      @cookies.map{ |k, v| "#{k}=#{v}" }.join('; ')
    end

  end
end
