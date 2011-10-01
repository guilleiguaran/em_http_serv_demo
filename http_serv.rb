require 'eventmachine'
require 'evma_httpserver'
require 'http/parser'

class HttpServ < EM::Connection
  include EM::HttpServer

  def post_init
    @parser = Http::Parser.new
    @body = ''
    @parser.on_body = proc do |chunk|
      @body << chunk
    end
    @parser.on_message_complete = method(:process_http_request)
  end

  def receive_data(data)
    @parser << data
  end

  def unbind
  end

  def process_http_request
    response = EM::DelegatedHttpResponse.new(self)
    response.status = 200
    response.content_type 'text/html'
    content = ''
    content << "<html><body>"
    content << "<p>HTTP_VERSION: #{@parser.http_major}.#{@parser.http_minor}</p>"
    content << "<p>HTTP_METHOD: #{@parser.http_method}</p>"
    content << "<p>REQUEST_URL: #{@parser.request_url}</p>"
    content << "<p>HEADERS:</p>"
    content << "<ul>"
    @parser.headers.each do |header, value|
      content << "<li>#{header}: #{value}</li>"
    end
    content << "</ul>"
    content << "</body></html>\r\n"
    response.content = content
    response.send_response
  end
end

EM.run do
  Signal.trap("INT")  { EM.stop }
  Signal.trap("TERM") { EM.stop }
  EM.start_server '0.0.0.0', 8080, HttpServ
  puts "Listening on port 8080"
end
