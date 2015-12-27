require 'qqbot/version'
require 'logger'

module QQBot

  LOGGER = Logger.new(STDOUT)

  autoload :Auth, 'qqbot/auth'
  autoload :Cookie, 'qqbot/cookie'
  autoload :Client, 'qqbot/client'
  autoload :Api, 'qqbot/api'
  autoload :Bot, 'qqbot/bot'

  def self.new
    QQBot::Bot.new
  end
end
