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
    
   # Configurer les certificats root (les mêmes que ceux des navigateurs)
   OpenID.fetcher.ca_file = "./config/ca-bundle.crt"
 end

puts "Environment : " + ENV['RACK_ENV']
run SinatraApp
