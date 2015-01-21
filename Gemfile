source 'https://rubygems.org'
ruby "2.1.2"
gem 'rails', '4.0.2'
gem 'activerecord-session_store'

group :development, :test do
  gem 'sqlite3'
  gem 'pry'
  gem 'better_errors'
  gem 'binding_of_caller'
end

# who needs staging anyway?

group :production do
  #gem 'mysql2'
  gem 'rack-timeout'
  gem 'unicorn'
  gem 'pg'
  gem 'thin'
  gem 'rails_12factor'
end

gem 'bcrypt-ruby', '~> 3.1.2'
gem 'sass-rails', '~> 4.0.0'
gem 'uglifier', '>= 1.3.0'
gem 'coffee-rails', '~> 4.0.0'
gem 'haml', '~> 4.0.0'
gem 'jquery-rails'
gem 'jquery-turbolinks'
gem 'jbuilder', '~> 1.2'
gem 'therubyracer'
gem 'websocket-rails'
gem 'bootstrap-sass'
gem 'will_paginate'
gem 'bootstrap-will_paginate'

group :doc do
  gem 'sdoc', require: false
end
