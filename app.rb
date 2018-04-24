# require dependencies

Bundler.require :web
Bundler.require :development if development?

helpers do
  def request_headers
    env.inject({}){|acc, (k,v)| acc[$1.downcase] = v if k =~ /^http_(.*)/i; acc}
  end
end

# serve stylesheet
get '/style.css' do
  scss :style
end

def process_login_request
    require 'net/http'

    uri = URI(request.url)
    if uri.path == '/login' and request.accept? 'application/html' and not request.accept? 'application/json'
      @nonce = (0...8).map { (65 + rand(26)).chr }.join
      return haml :index
    else
      real_uaa = "uaa.hector.dev.cloudpipeline.digital"
      # real_uaa = "cf-env.hector.dev.cloudpipelineapps.digital"

      uri.host = real_uaa

      client_request = Net::HTTP::Get.new(uri)
      request_headers.to_hash.each { |h,v|
        next if h == 'host'
        client_request[h]= v
      }

      client_request['Host'] = real_uaa
      server_response = Net::HTTP.start(
        real_uaa,
        :use_ssl => true
      ) do |http|
        http.request(client_request)
      end

      status server_response.code
      server_response.to_hash.each {|h,v|
        next if h == 'transfer-encoding'
        headers h => v
      }
      server_response.body
    end
end

# our basic route which renders the index view
[ '/', '/login' ].each { |path|
  get path do
    process_login_request
  end
}

# our not-found route which serves the 404 view
not_found do
  process_login_request
end
