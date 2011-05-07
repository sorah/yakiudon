$:.unshift File.dirname(__FILE__)

require 'rubygems'

module Yakiudon
  CONFIG = "#{File.dirname(__FILE__)}/../config.yml"
end

require "yakiudon/config"
require "yakiudon/misc"
require "yakiudon/model"
require "yakiudon/html"

