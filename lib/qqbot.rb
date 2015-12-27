require 'qqbot/version'

module QQBot

  autoload :Auth, 'qqbot/auth'
  autoload :Cookie, 'qqbot/cookie'
  autoload :Client, 'qqbot/client'
  autoload :Api, 'qqbot/api'
  autoload :Bot, 'qqbot/bot'

  def self.new
    QQBot::Bot.new
  end
end
