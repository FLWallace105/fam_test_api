require 'sinatra/activerecord/rake'

namespace :db do
  task :load_config do
    require 'dotenv'
    Dotenv.load
    require "./app"
  end
end
