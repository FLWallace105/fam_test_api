require_relative 'app'
require 'sinatra'

use Rack::ContentLength
run Sinatra::Application
#run Recharge
