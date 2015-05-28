# -*- encoding: utf-8 -*-

$LOAD_PATH.unshift(File.dirname(__FILE__))

require './config/init'
require 'app'

# Déclaration de la session Rack utilisée par sinatra
use Rack::Session::Cookie, key: 'rack.session',
                           domain: 'localhost',
                           secret: 'secret1'

 use OmniAuth::Builder do
    provider :openid_connect, FRANCE_CONNECT::CONFIG
    # {    
    #       scope: [:openid, :profile], 
    #       response_type: :code,
    #       state: true, # Requis par France connect
    #       nonce: true, # Requis par France connect
    #       issuer: "http://fcp.integ01.dev-franceconnect.fr", # L'environnement d'intégration utilise 'http' et pas 'https'
    #       # Ce qui ne sera peut-être pas le cas sur l'environnement de production. (voir si il ne faudra pas le canger en production.)
    #       client_auth_method: "Custom", # France connect n'utilise pas l'authent "BASIC".
    #       client_signing_alg: :HS256,   # Format de hashage France Connect
    #       client_options: {
    #               identifier: 'b8da984eb141173a6fa291b6f1389a92b9b8ebdab2a056d5e57c734f88e31339',
    #               # utile pour la gem omniauth-openid-connect
    #               secret: 'b7be905ae14a9e3037589a594c4d1708a0616aad521ee7f18e41e6b4b0960d44',
    #               # Utile pour la gem openid_connect
    #               client_secret: 'b7be905ae14a9e3037589a594c4d1708a0616aad521ee7f18e41e6b4b0960d44',
    #               port: 443,
    #               scheme: 'https',
    #               host: 'fcp.integ01.dev-franceconnect.fr',
    #               redirect_uri: 'http://localhost:9292/auth/openidconnect/callback',
    #               # Tous les points d'entrée sont à configurer explicitement pour ne pas utiliser le param 'discover' 
    #               # qui n'est pas configuré côté France Connect. 
    #               authorization_endpoint: "/api/v1/authorize",
    #               token_endpoint: "/api/v1/token",
    #               userinfo_endpoint: "/api/v1/userinfo",
    #             },
    #           }
  # Configurer les certificats root (les mêmes que ceux des navigateurs)
   OpenID.fetcher.ca_file = "./config/ca-bundle.crt"
 end

puts "Environment : " + ENV['RACK_ENV']
run SinatraApp
