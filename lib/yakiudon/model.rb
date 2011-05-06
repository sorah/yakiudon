require 'yaml'
require 'bluecloth'

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
          YAML.dump(@@data,open(FILE,"w"))
          self
        end
      end
    end

    class Day
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
        @markdown
      end

      def html
        if @html; @html
        elsif File.exist?(@html_path); @html = File.read(@html_path)
        else; nil
        end
      end

      def meta
        Meta["article"] ||= {}
        Meta["article"][@id] ||= {}
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
