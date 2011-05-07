require 'yaml'

module Yakiudon
	module Config
		class << self
			def read
				@@yaml ||= {"public"      => "#{File.dirname(__FILE__)}/../../public",
										"template"    => "#{File.dirname(__FILE__)}/../../template",
										"db"          => "#{File.dirname(__FILE__)}/../../db",
										"user"        => "yaki",
										"password"    => "udon",
										"recent"      => 10,
										"url"         => "/",
				            "title"       => "Untitled Yakiudon",
				            "description" => "With some chunky bacons.",
				            "head_shift"  => 3}
				@@yaml.merge!(YAML.load_file(CONFIG)) if File.exist?(CONFIG)
				@@yaml["url"].sub!(/\/$/,"")
				@@yaml
			end

			def method_missing(name,*args)
				self.read[name.to_s]
			end

			def yaml; @@yaml; end
			def yaml=(x); @@yaml = x; end
		end
	end
end
