require 'rubygems'
require 'bundler'

Bundler.setup :default, :development, :example
require 'sinatra'
require 'sinatra/advanced_routes'
require 'omniauth'
require 'omniauth-openid'
require 'omniauth-openid-connect'
require 'openid/store/filesystem'
require 'openid/fetchers'

# Application Sinatra servant de base
class SinatraApp < Sinatra::Base
  configure do
    set :app_file, __FILE__
    set :root, APP_ROOT
    set :public_folder, proc { File.join(root, 'public') }
    set :inline_templates, true
    set :protection, true
  end

  get '/' do
    erb :index
  end

  [:get, :post].each do |method|
    send method, '/auth/:provider/callback' do
      # Ici on stocke le user connecté dans la session
      # on pourrait le mettre en base et en profiter pour mettre à jour des données ou
      # les enrichir avec des données locales
      session[:user] = request.env['omniauth.auth']['extra']['raw_info']
      session[:crendentials] = request.env['omniauth.auth']['credentials'].reject { |k| k == 'id_token' }
      redirect to '/mon_profil'
    end
  end

  get '/mon_profil' do
    if session[:user]
      # on retrouve le user connecté (souvent en base, ici en session pour commodité)
      @user = session[:user]
      @credentials = session[:crendentials]
      erb :userinfo
    else
      erb 'Veuillez vous connecter'
    end
  end
end

SinatraApp.run! if __FILE__ == $PROGRAM_NAME
