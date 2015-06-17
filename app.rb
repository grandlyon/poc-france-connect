require 'rubygems'
require 'bundler'

require 'sinatra'
require 'sinatra/advanced_routes'
require 'omniauth'
require 'omniauth-openid'
require 'omniauth-openid-connect'
require 'openid/store/filesystem'
require 'openid/fetchers'
require 'rest_client'

# Application Sinatra servant de base
class SinatraApp < Sinatra::Base
  configure do
    set :app_file, __FILE__
    set :root, APP_ROOT
    set :public_folder, proc { File.join(root, 'public') }
    set :inline_templates, true
    set :protection, true
  end

  helper do
    # Récupération de doonées
    def receive_data()
      http = Net::HTTP.new(FRANCE_CONNECT::CONFIG[:data_provider][:host], 80)
      # puts FRANCE_CONNECT::CONFIG[:data_provider].inspect
      # puts @credentials['token'].inspect
      req = Net::HTTP::Get.new("#{FRANCE_CONNECT::CONFIG[:data_provider][:url]}&scope=#{FRANCE_CONNECT::CONFIG[:data_provider][:scope]}", { 'Authorization' => "Bearer #{@credentials['token']}"})
      res = http.request(req)
      JSON.parse(res.body)
    end
  end

  get '/' do
    erb :index
  end

  [:get, :post].each do |method|
    send method, '/auth/:provider/callback/?' do
      # Ici on stocke le user connecté dans la session
      # on pourrait le mettre en base et en profiter pour mettre à jour des données ou
      # les enrichir avec des données locales
      session[:user] = request.env['omniauth.auth']['extra']['raw_info']
      session[:crendentials] = request.env['omniauth.auth']['credentials']
      @code = request.env['code']
      redirect to '/etape1'
    end
  end

  get '/etape1' do
    if session[:user]
      # on retrouve le user connecté (souvent en base, ici en session pour commodité)
      @user = session[:user]
      @credentials = session[:crendentials].reject { |k| k == 'id_token' }
      # @data = receive_data
      erb :etape1
    else
      erb 'Veuillez vous connecter' # TODO : Faire un erb de connexion
    end

    get '/etape2' do
      # @data = receive_data
      erb :etape2
    end

  end
end

SinatraApp.run! if __FILE__ == $PROGRAM_NAME
