require 'rack'
require 'json'

module Tang

  class Resources 
    class Resource
      attr_reader :name
      def initialize(name)
        @data = {}
        @name = name
      end

      def index
        ["200", {'Content-Type' => 'text/html'}, @data.values.to_json]
      end

      def create(id, content)
        json = JSON.parse(content)
        id = json["id"]
        id = SecureRandom.uuid unless id
        @data[id] = json
        ["201", {'Content-Type' => 'text/html'}, id]
      end

      def destroy(id)
        @data.delete id 
        ["200", {'Content-Type' => 'text/html'}, ""]
      end

      def update(id, content)
        @data[id] = JSON.parse(content)
        ["200", {'Content-Type' => 'text/html'}, ""]
      end

      def show(id)
        ["200", {'Content-Type' => 'text/html'},@data[id].to_json]
      end

      def match?(req)
        case req.path_info
        when /^\/#{@name}$/
          req.get? or req.post?
        when /^\/#{@name}\/(.+)$/
          req.get? or req.put? or req.delete?
        else
          false
        end
      end
      def respond(req)
        case req.path_info
        when /^\/#{@name}$/
          if req.get? 
            index
          elsif req.post?
            create(req['id'], req['content'])
          else
            not_found
          end
        when /^\/#{@name}\/(.+)$/
          if req.get?
            show($1)
          elsif req.put?
            update($1, req['content'])
          elsif req.delete?
            destroy($1)
          else
            not_found
          end
        else
          not_found
        end
      end

      def not_found
        ["404", {'Content-Type' => 'text/html'}, "Not found"]
      end
    end

    def initialize()
      @resources = {}
    end
    def match(req)
      @resources.values.find do |r|
        r.match? req
      end
    end
    def index
      @resources.keys.to_json
    end
    def create(name)
      @resources[name] = Resource.new(name)
    end
    def destroy(name)
      @resources.delete name 
    end
  end

  class App
    def initialize
      @resources= Resources.new 
    end

    def call(env)
      req = Rack::Request.new(env)

      case req.path_info
      when /^\/_$/
        if req.get?
          ['200', {'Content-Type' => 'text/html'}, @resources.index]
        elsif req.post?
          resource = req['resource']
          @resources.create(resource)
          ['201', {'Content-Type' => 'text/html'}, "Created"]
        end
      when /^\/_\/(.+)$/
        if req.delete?
          resource = req['resource']
          @resources.destroy($1)
          ['200', {'Content-Type' => 'text/html'}, "deleted"]
        end
      else
        resource = @resources.match req
        if resource 
          resource.respond req
        else
          ['404', {'Content-Type' => 'text/html'}, ["not found #{req.path_info}"]]
        end
      end
    end
  end
end

Rack::Server.start :app => Tang::App.new, :Port => 3000
