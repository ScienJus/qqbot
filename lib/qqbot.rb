require_relative 'qqbot/version'
require_relative 'qqbot/auth'
require_relative 'qqbot/cookie'

module QQBot
  # Your code goes here...
  # autoload :Auth, 'qqbot/auth'
  # autoload :Cookie, 'qqbot/cookie'

  def self.new
    QQBot::Auth.new
  end
end
