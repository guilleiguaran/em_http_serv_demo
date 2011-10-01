require 'bundler'
Bundler.setup

require 'eventmachine'
require 'evma_httpserver'
require 'http/parser'
require 'optparse'
require 'logger'

port = 8080
optparse = OptionParser.new do |opts|
  opts.on("-p", "--port PORT", Integer, "Port to listen") do |p|
    port = p
  end
end
optparse.parse!

ServLogger = Logger.new(STDOUT)
ServLogger.level = Logger.const_get("INFO")

class HttpServ < EM::Connection
  include EM::HttpServer

  def post_init
    @start_time = Time.now
    @parser = Http::Parser.new
    @body = ''
    @parser.on_headers_complete = proc do
      log_time("=> Parse time")
    end
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
    content << "<p>REQUEST_PATH: #{@parser.request_path}</p>"
    content << "<p>QUERY_STRING: #{@parser.query_string}</p>"
    content << "<p>HEADERS:</p>"
    content << "<ul>"
    @parser.headers.each do |header, value|
      content << "<li>#{header}: #{value}</li>"
    end
    content << "</ul>"
    content << "</body></html>"
    response.content = content
    response.send_response
    log_time("<= Response time")
  end

  private

  def log_time(message)
    time = (Time.now - @start_time)*1000
    ServLogger.info "#{@parser.http_method} #{@parser.request_url} #{message}: #{time}ms"
  end
end

EM.run do
  Signal.trap("INT")  { EM.stop }
  Signal.trap("TERM") { EM.stop }
  EM.start_server '0.0.0.0', port, HttpServ
  ServLogger.info "Listening on port #{port}"
end
