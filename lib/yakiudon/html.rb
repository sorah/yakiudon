require 'fileutils'
require 'erb'
require 'time'
require 'json'

module Yakiudon
  module HTML
    class << self
      include ERB::Util

      def render(e="")
        if File.exist?("#{Config.template}/layout.erb")
          b = binding
          eval e, b
          ERB.new(File.read("#{Config.template}/layout.erb")).result(b)
        else
          yield
        end
      end

      def build(*files)
        files.each do |f|
          title = nil
          case f
          when "index.html"
            days = Model::Meta["file"]["index.html"].map { |i| Model::Day.new(i) }
            result = self.render("title = #{title.inspect}") { ERB.new(File.read("#{Config.template}/index.erb")).result(binding) }
            open("#{Config.public}/index.html","w"){|io|io.puts result}
          when "index.json"
            days = Model::Meta["file"]["index.html"].map { |i| Model::Day.new(i) }
            result = {"days" => days.map(&:to_hash)}
            open("#{Config.public}/index.json","w"){|io|io.puts result}
          when "feed.xml"
            days = Model::Meta["file"]["feed.xml"].map { |i| Model::Day.new(i) }
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
        #{h d.html}
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
            open("#{Config.public}/feed.xml","w"){|io|io.puts r}

          when /^(\d\d\d\d)(\d\d).(html|json)$/
            year = $1
            month = $2
            is_json = $3 == "json"
            days = Model::Meta["file"]["#{year}#{month}.html"].map { |i| Model::Day.new(i) }
            if is_json
              result = {"year" => year.to_i, "month" => month.to_i,
                        "days" => days.map(&:to_hash)}.to_json
              open("#{Config.public}/#{year}#{month}.json","w"){|io|io.puts result}
            else
              title = "#{year}/#{month}"
              result = self.render("title = #{title.inspect}") { ERB.new(File.read("#{Config.template}/month.erb")).result(binding) }
              open("#{Config.public}/#{year}#{month}.html","w"){|io|io.puts result}
            end
          when /^(\d\d\d\d)(\d\d)(\d\d).(html|json)$/
            year = $1
            month = $2
            day = $3
            is_json = $4 == "json"
            p [year,month,day,is_json,f]
            d = Model::Day.new("#{year}#{month}#{day}")
            if is_json
              result = {"year" => year.to_i, "month" => month.to_i, "day" => day.to_i}.merge(d.to_hash).to_json
              open("#{Config.public}/#{year}#{month}#{day}.json","w"){|io|io.puts result}
            else
              title = "#{year}/#{month}/#{day} #{d.meta["title"]}"
              result = self.render("title = #{title.inspect}") { ERB.new(File.read("#{Config.template}/day.erb")).result(binding) }
              open("#{Config.public}/#{year}#{month}#{day}.html","w"){|io|io.puts result}
            end
          end
        end
        FileUtils.cp_r(Dir["#{Config.template}/raw/*"],Config.public)
      end

      def build_includes(*ids)
        self.build(*ids.map{|x| Model::Meta.files_include(x) }.flatten.uniq)
      end

      def build_all
        diarys = Dir["#{Config.db}/*.html"].map{|fn| fn.sub(Config.db+"/","") }
        files =  [diarys]
        files << diarys.map{|fn| fn.gsub(/\d\d.html$/,".html") }.uniq
        files << diarys.map{|fn| fn.gsub(/\d\d.html$/,".json") }.uniq
        files << diarys.map{|fn| fn.gsub(/.html$/,".json") }.uniq
        files << "index.html"
        files << "index.json"
        files << "feed.xml"

        self.build(*files.flatten.uniq)

        self
      end

      def renew_index
        Model::Meta["file"]["index.html"] = Model::Day.all.map{|d|d.id}.sort.reverse.take(Config.recent)
        Model::Meta["file"]["index.json"] = Model::Day.all.map{|d|d.id}.sort.reverse.take(Config.recent)
        Model::Meta["file"]["feed.xml"] = Model::Meta["file"]["index.html"]
      end
    end
  end
end

