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

require 'base64'
require 'cgi'
require 'openssl'


# Application Sinatra servant de base
class SinatraApp < Sinatra::Base
  configure do
    set :app_file, __FILE__
    set :root, APP_ROOT
    set :public_folder, proc { File.join(root, 'public') }
    set :inline_templates, true
    set :protection, true
  end

  helpers do
    # signe une requête
    def sign( service, service_url, args )
      @app_id = 'SACOCHE'
      @api_key = 'REGg3iFRmUDqEK/JKgo4Qgj8bDeOQEuhzFoZ8Z30RJo='
      @api_url = 'https://v3dev.laclasse.com/api'
      @url = 'app/users/'
      uri = @api_url
      # remove "/" symbole
      uri = uri.chop if uri[ -1, 1 ] == '/'
      service = @url
      service += service_url unless service_url.nil?
      service = service.chop if service[ -1, 1 ] == '/'
      service.slice!(0) if service[0] == '/'
      timestamp = Time.now.getutc.strftime('%FT%T')
      canonical_string = "#{uri}/#{service}?"
      canonical_string += Hash[ args.sort ]
      .map { |key, value| "#{key}=#{value.is_a?( String ) ? CGI.escape(value) : value}" }
      .join( '&' )
      canonical_string += ";#{timestamp};#{@app_id}"
      puts "args #{args} , canonical_string #{canonical_string}"
      digest = OpenSSL::Digest.new( 'sha1' )
      digested_message = Base64.encode64( OpenSSL::HMAC.digest( digest, @api_key, canonical_string ) )
      query = args.map { |key, value| "#{key}=#{value.is_a?( String ) ? CGI.escape(value) : value}" }.join( '&' )
      signature = { app_id: @app_id,
                    timestamp: timestamp,
                    signature: digested_message }
      .map { |key, value| "#{key}=#{value.is_a?( String ) ? CGI.escape(value) : value}" }
      .join( ';' )
      .chomp
      "#{uri}/#{service}?#{query};#{signature}"
    end

    # Récupération de doonées
    def receive_data( dataset_name, token, qry )
      http = Net::HTTP.new(FRANCE_CONNECT::CONFIG[:data_providers][dataset_name][:host], 80)
      puts "http://#{FRANCE_CONNECT::CONFIG[:data_providers][dataset_name][:host]}#{FRANCE_CONNECT::CONFIG[:data_providers][dataset_name][:uri]}&#{qry}"
      req = Net::HTTP::Get.new("http://#{FRANCE_CONNECT::CONFIG[:data_providers][dataset_name][:host]}#{FRANCE_CONNECT::CONFIG[:data_providers][dataset_name][:uri]}&#{qry}", { 'Authorization' => "Bearer #{token}"})
      res = http.request(req)
      JSON.parse(res.body)
    end

    @@scope = "ods_etatcivil_cnf"

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
      erb :etape1
    else
      erb 'Veuillez vous connecter' # TODO : Faire un erb de connexion
    end

  end

  get '/etape2' do
    @credentials = session[:crendentials].reject { |k| k == 'id_token' }
    puts session.inspect
    @data = receive_data 'justificatif_de_domicile', @credentials['token'], 'q=nom_de_naissance%3D' + session[:user]['family_name']
    @qf = receive_data 'quotien_familial', @credentials['token'], 'q=nom_de_naissance%3D' + session[:user]['family_name']
    puts @data.inspect
    erb :etape2
  end

  get '/test' do
    req = sign 'app/users/', "123" , 'expand' => 'true'  #params[:id]
    puts req
    erb "<hr><a href='#{req}' target='_blank'>#{req}</a><hr>"
  end

end

SinatraApp.run! if __FILE__ == $PROGRAM_NAME
