require 'sinatra'

helpers do
  def protected!
    unless authorized?
      response['WWW-Authenticate'] = %(Basic realm="Give me bacon!")
      throw(:halt, [401, "Not authorized\n"])
    end
  end

  def authorized?
    @auth ||=  Rack::Auth::Basic::Request.new(request.env)
    @auth.provided? && @auth.basic? && @auth.credentials && @auth.credentials == [Yakiudon::Config.user, Yakiudon::Config.password]
  end
end

get "/edit/:id" do
	protected!
	id = params[:id].gsub(/[^\d]/,"")
	@day = Yakiudon::Model::Day.new(id)
	erb :edit
end

get "/edit" do
	redirect "#{Yakiudon::Config.url}/edit/#{Time.now.strftime("%Y%m%d")}"
end

post "/edit/:id" do
	protected!
	id = params[:id].gsub(/[^\d]/,"")
	return "invalid id" unless id.size == 8
  day = Yakiudon::Model::Day.new(id)
	day.markdown = params[:body]
	day.save

	Yakiudon::HTML.renew_index
	Yakiudon::Model::Meta.save
	Yakiudon::HTML.build_includes(id)

	redirect "#{Yakiudon::Config.url}/#{id}.html"
end

post "/build" do
	protected!
end
