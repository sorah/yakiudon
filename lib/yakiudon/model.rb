require 'yaml'
require 'bluecloth'
require 'erb'

module Yakiudon
  module Model
    module Meta
      FILE = "#{Config.db}/meta.yml"

      class << self
        def read
          if File.exist?(FILE)
            @@data ||= YAML.load_file(FILE)
          else
            @@data ||= {}
          end
          @@data["file"] ||= {}
        end

        def method_missing(name,*args)
          self.read
          @@data.__send__(name,*args)
        end

        def files_include(fn)
          self.read
          return [] unless @@data["file"]
          @@data["file"].select do |k,v|
            v.include?(fn)
          end.map{|k,v| k }
        end

        def save
          open(FILE,"w"){|io| io.puts YAML.dump(@@data) }
          self
        end
      end
    end

    class Day
      include ERB::Util

      SUFFIX_MARKDOWN = ".mkd"
      SUFFIX_HTML = ".html"

      def self.all
        Dir["#{Config.db}/*.html"].select{|f| /\/\d{8}.html$/ =~ f } \
                                  .map{|f| self.new(f.sub(Config.db+"/","").sub(/\.html$/,"")) }
      end

      def initialize(id)
        @id = id.sub(/\.html$/,"").sub(/^.+\//,"").gsub(/[^\d]/,"")
        @html_path     = "#{Config.db}/#{id}#{SUFFIX_HTML}"
        @mkd_path      = "#{Config.db}/#{id}#{SUFFIX_MARKDOWN}"
      end

      attr_reader :id

      def markdown
        if @markdown; @markdown
        elsif File.exist?(@mkd_path); @markdown = File.read(@mkd_path)
        else; nil
        end
      end

      def markdown=(x)
        @markdown = x
        @html = BlueCloth.new(@markdown).to_html
        @html.gsub!(/<(\/?)h(.)>/){|str| "<#{$1}h#{(_=$2.to_i+Config.head_shift) >= 6 ? 6 : _}>"}
        @markdown
      end

      def html
        if @html; @html
        elsif File.exist?(@html_path); @html = File.read(@html_path).force_encoding("UTF-8")
        else; nil
        end
      end

      def meta
        Meta["article"] ||= {}
        Meta["article"][@id] ||= {}
      end

      def delete
        if File.exist?("#{Config.public}/#{@id}.html")
          File.safe_delete("#{Config.public}/#{@id}.html")
        end
        if File.exist?("#{Config.db}/#{@id}.mkd")
          File.safe_delete("#{Config.db}/#{@id}.mkd")
        end
        if File.exist?("#{Config.db}/#{@id}.html")
          File.safe_delete("#{Config.db}/#{@id}.html")
        end

        Meta["file"].delete("#{@id}.html")
        Meta["article"].delete(@id)

        a = Meta.files_include(@id)
        a.each do |f|
          Meta["file"][f].delete(@id)
          if Meta["file"][f].empty? && f != "index.html"
            File.safe_delete("#{Config.public}/#{f}")
            a.delete(f)
          end
        end
        Yakiudon::HTML.renew_index
        Meta.save
        Yakiudon::HTML.build(*a)

        a
      end

      def render
        day = self
        ERB.new(File.read("#{Config.template}/article.erb")).result(binding)
      end

      def save
        if @markdown
          open(@mkd_path,"w") do |io|
            io.puts @markdown 
          end
        end
        if @html
          open(@html_path,"w") do |io|
            io.puts @html
          end
        end
        self.meta["updated_at"] = Time.now
        self.meta["created_at"] ||= self.meta["updated_at"]
        Meta["file"]["#{@id}.html"] = [@id]
        Meta["file"]["#{@id[0..5]}.html"] ||= []
        Meta["file"]["#{@id[0..5]}.html"] << @id unless Meta["file"]["#{@id[0..5]}.html"].include?(@id)
        self
      end
    end
  end
end
