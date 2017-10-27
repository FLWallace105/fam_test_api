require 'sinatra'
require 'active_record'
require 'sinatra/activerecord'
require 'json'
require 'pg'
require 'httparty'
require 'dotenv'
require 'pry-byebug'

configure do
  enable :logging
  set :server, :puma
  set :database_file, 'config/database.yml'
  Dotenv.load
  $logger = Logger.new STDOUT
  $logger.level = Logger::DEBUG
end

require_relative 'models'

class Recharge
  include HTTParty

  attr_reader :access_token, :default_headers

  @@sleep_time = ENV['RECHARGE_SLEEP_TIME']
  @@base_uri = 'https://api.rechargeapps.com'

  def initialize(*args)
    @access_token = ENV['RECHARGE_ACCESS_TOKEN']
    @default_headers = {
      'X-Recharge-Access-Token' => @access_token,
      'Accept' => 'application/json',
      'Content-Type' => 'application/json',
    }
  end

  def subscriptions_by_shopify_id(shopify_id)
    customer = Customer.find_by(shopify_customer_id: shopify_id)
    return [] if customer.nil?
    res = HTTParty.get("#{@@base_uri}/subscriptions?customer_id=#{customer.customer_id}", headers: @default_headers)
    if res.ok?
      $logger.debug 'response was ok!'
      res.parsed_response['subscriptions']
    else
      $logger.debug 'response was NOT ok!'
      $logger.debug res.request.uri
      $logger.debug res.code
      $logger.debug default_headers
      $logger.debug res.body
      []
    end
  end
end

def transform_subscriptions(sub)
  $logger.debug "subscription: #{sub.inspect}"
  size_properties = ['leggings', 'tops', 'sports-jacket', 'sports-bra']
  { 
    charge_date: Date::parse(sub['next_charge_scheduled_at'])
      .strftime('%Y-%m-%d'),
    sizes: sub['properties']
      .select {|p| size_properties.include? p['name']}
      .map{|p| [p['name'], p['value']]}
      .to_h,
  }
end

get '/subscriptions' do 
  shopify_id = params['shopify_id']
  unless shopify_id.instance_of? Integer
    return [400, JSON.generate({error: 'shopify_id required'})]
  end
  subscriptions = Recharge.new.subscriptions_by_shopify_id shopify_id
  output = subscriptions.map{|sub| transform_subscriptions(sub)}
  [200, JSON.generate(output)]
end

post '/subscriptions' do
  json = JSON.parse request.body.read
  shopify_id = json['shopify_id']
  unless shopify_id.instance_of? Integer
    return [400, JSON.generate({error: 'shopify_id required'})]
  end
  subscriptions = Recharge.new.subscriptions_by_shopify_id shopify_id
  output = subscriptions.map{|sub| transform_subscriptions(sub)}
  [200, JSON.generate(output)]
end
