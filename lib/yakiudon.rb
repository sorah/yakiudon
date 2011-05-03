$:.unshift File.dirname(__FILE__)

module Yakiudon
  PUBLIC = "#{File.dirname(__FILE__)}/../public"
  TEMPLATE = "#{File.dirname(__FILE__)}/../template"
  DB = "#{File.dirname(__FILE__)}/../db"
end

require "yakiudon/model"
require "yakiudon/html"
require "yakiudon/editor"
