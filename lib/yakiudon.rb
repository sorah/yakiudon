$:.unshift File.dirname(__FILE__)

require 'rubygems'

module Yakiudon
  CONFIG = "#{File.dirname(__FILE__)}/../config.yml"
end

require "yakiudon/config"
require "yakiudon/model"
require "yakiudon/html"

if __FILE__ == $0
  require "sinatra"
  require "yakiudon/editor"
end
