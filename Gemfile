source 'https://rubygems.org'
ruby File.read('.ruby-version', mode: 'rb').chomp
#ruby-gemset=00-default-dokku

gem 'rack'
gem "sinatra"

group :development do
  gem "webrick"
end

group :production do
	gem "iodine"
end
