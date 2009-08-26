# TITLE:
#
#   Raze Server
#
# SUMMARY:
#
#   The Raze server uses Rack to provide a simple means of serving
#   a Raze-based site. One can use this as an alternative to
#   generating the site, or simply for testing purposes before
#   deploying.

require 'webrite/page'

begin
  require 'rack'
  require 'rack/request'
  require 'rack/response'
rescue LoadError => e
  if require 'rubygems'
    retry
  else
    raise e
  end
end


module Webrite

  # TODO Make alterable?

  def self.root
    Dir.pwd
  end

  # = Raze Rack-based Server
  #
  # The server looks for a configuration file 'server.yaml' in your raze site's
  # root directory. These are configuration options fed to Rack's handler. Use
  # 'adapter' entry in this to select which handler to use (webrick, cgi, fcgi).
  # If not server.yaml file is found, or entries not given, the deafult settings
  # are Webrick on port 8181.

  class Server

    DEFAULT_ROUTE = "routes.yaml"

    DEFAULT_CONFIG = { 'port' => 8181 }

    def self.adapters(name)
      case name..to_s.downcase
      when 'webrick'
        Rack::Handler::WEBrick
      when 'cgi'
        Rack::Handler::CGI
      when 'fcgi'
        Rack::Handler::FastCGI
      else
        Rack::Handler::WEBrick
      end
    end

    # Go Raze!

    def self.start
      config  = load_config
      adapter = config.delete(:Adapter)
      #use Rack::ShowExceptions
      server = Raze::Server.new

      adapters(adapter).run(server, config)
    end

    # Load server configuration.

    def self.load_config
      default = DEFAULT_CONFIG
      if File.file?('server.yaml')
        default.update(YAML.load(File.new("server.yaml")))
      end
      default.inject({}){|m, (k,v)| m[k.capitalize.to_sym] = v; m}
    end

    # Shiny new Raze site server.

    def initialize
      #load_config
      load_routes
    end

    # Load routes.

    def load_routes
      @routes = []
      routes = YAML.load(DEFAULT_ROUTE)
      routes.each do |target, parts|
        puts "[Add Route] " + target
        #name = name.chomp(File.extname(name))
        load_route(target, parts)
      end
    end

    # Load a route.

    def load_route(target, parts)
      @routes << Route.new(target, parts)
    end

    # for rack

    def call(env)
      req = Request.new(
        :method => env['REQUEST_METHOD'], # GET/POST
        :script => env['SCRIPT_NAME'],    # The initial portion of the request URL’s "path" that corresponds to the application object, so that the application knows its virtual "location". This may be an empty string, if the application corresponds to the "root" of the server.
        :path   => env['PATH_INFO'],      # The remainder of the request URL’s "path", designating the virtual "location" of the request’s target within the application. This may be an empty string, if the request URL targets the application root and does not have a trailing slash.
        :query  => env['QUERY_STRING'],   # The portion of the request URL that follows the ?, if any. May be empty, but is always required!
        :domain => env['SERVER_NAME'],    # When combined with SCRIPT_NAME and PATH_INFO, these variables can be used to complete the URL. Note, however, that HTTP_HOST, if present, should be used in preference to SERVER_NAME for reconstructing the request URL. SERVER_NAME and SERVER_PORT can never be empty strings, and so are always required.
        :port   => env['SERVER_PORT']
        #env['HTTP_???']
      )
      return respond(req)
    end

    # Respond to request.

    def respond(request)
      puts "[Request] " + request.path

      route = find_route(request.path)
      if route
        status, header, body = route.respond(request)
      else
        path = request.path
        path = path[1..-1] if path[0,1] == '/'
        if File.exist?(path) # pass through to webserver?
          status = 200
          header = {"Content-Type" => "text/plain"}  # how to decipher?
          body   = File.new(path)
        else
          status = 404
          header = {"Content-Type" => "text/html"}
          body = "<h1>404</h1>"  # FIX just return rack exception page if development mode.
        end
      end

      return status, header, body
    end

    # Find a route for the given url.

    def find_route(url)
      @routes.each do |route|
        if route.match(url)
          return route
        end
      end
      nil
    end

  end


  # Site Request

  class Request
    attr_accessor :method
    attr_accessor :script
    attr_accessor :path
    attr_accessor :query
    attr_accessor :domain
    attr_accessor :port

    def initialize(options)
      options.each do |k,v| send("#{k}=", v) end
    end
  end


  # Site Route

  class Route
    attr :route
    attr :parts

    #def self.load(file)
    #  new(YAML.load(File.new(file)))
    #end

    def initialize(route, parts)
      @route = route #'/' + File.basename(file).chomp('.raze')
      @parts = parts
    end

    def match(url)
      route == url || route + 'html' == url
      #Regexp.new(@route).match(url)
    end

    def respond(request)
      body = Page.new(route, parts).to_html
      return 200, {"Content-Type" => "text/html"}, [body]
    end

  end

end
