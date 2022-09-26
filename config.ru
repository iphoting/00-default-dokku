require 'sinatra'

get '/**' do
	status 410
end

run Sinatra::Application
