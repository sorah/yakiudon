require 'fileutils'
require 'cgi'
require 'erb'
require 'time'

module Yakiudon
  module HTML
    class << self
      def build(*files)
        files.each do |f|
          case f
          when "index.html"
            days = Model::Meta["index.html"].map { |i| Model::Day.new(i) }
            result = ERB.new(File.read("#{Config.template}/index.erb")).result(binding) 
            open("#{Config.public}/index.html","w"){|io|io.puts result}

          when "feed.rdf"
            days = Model::Meta["feed.rdf"].map { |i| Model::Day.new(i) }
            r = <<-EOR
<?xml version="1.0" encoding="UTF-8" ?>
<rss version="2.0">
  <channel>
    <title>#{Config.title}</title>
    <description>#{Config.description}</description>
    <link>#{Config.url}/</link>
    <lastBuildDate>#{days[0].meta["updated_at"].rfc822}</lastBuildDate>
    <pubDate>#{days[0].meta["created_at"].rfc822}</pubDate>
            EOR
            days.each do |d|
              r += <<-EOR
    <item>
      <title>#{d.id}</title>
      <description>
        #{CGI.escapeHTML(d.html)}
      </description>
      <link>#{Config.url}/#{d.id}.html</link>
      <guid>#{Config.url}/#{d.id}.html</guid>
      <pubDate>#{d.meta["created_at"].rfc822}</pubDate>
    </item>
              EOR
            end
            r += <<-EOR
  </channel>
</rss>
            EOR
            open("#{Config.public}/feed.rdf","w"){|io|io.puts r}

          when /^(\d\d\d\d)(\d\d).html$/
            year = $1
            month = $2
            days = Model::Meta["file"]["#{year}#{month}.html"].map { |i| Model::Day.new(i) }
            result = ERB.new(File.read("#{Config.template}/month.erb")).result(binding) 
            open("#{Config.public}/#{year}#{month}.html","w"){|io|io.puts result}
          when /^(\d\d\d\d)(\d\d)(\d\d).html$/
            year = $1
            month = $2
            day = $3
            d = Model::Day.new("#{year}#{month}#{day}")
            result = ERB.new(File.read("#{Config.template}/day.erb")).result(binding) 
            open("#{Config.public}/#{year}#{month}#{day}.html","w"){|io|io.puts result}
          end
        end
      end

      def build_includes(*ids)
        self.build(*ids.map{|x| Model::Meta.files_include(x) }.flatten.uniq)
      end

      def build_all
        diarys = Dir["#{Config.db}/*.html"].map{|fn| fn.sub(Config.db+"/","") }
        files =  [diarys]
        files << diarys.map{|fn| fn.gsub(/\d\d.html$/,".html") }.uniq
        files << "index.html"
        files << "feed.rdf"

        files.uniq

        FileUtils.cp_r(Dir["#{Config.template}/raw/*"],Config.public)
        self
      end

      def renew_index
        Model::Meta["file"]["index.html"] = Model::Day.all.map{|d|d.id}.sort.reverse.take(Config.recent)
        Model::Meta["file"]["feed.rdf"] = Model::Meta["file"]["index.html"]
      end
    end
  end
end

