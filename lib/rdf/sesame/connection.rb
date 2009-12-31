require 'net/http'

module RDF::Sesame
  ##
  # A connection to a Sesame 2.0-compatible HTTP server.
  #
  # Instances of this class represent HTTP connections to a Sesame server,
  # abstracting away the protocol and transport-level details of how the
  # connection is actually established and how requests and responses are
  # implemented and performed.
  #
  # Currently, connections are internally implemented using
  # [`Net::HTTP`](http://ruby-doc.org/core/classes/Net/HTTP.html) from
  # Ruby's standard library, and connections are always transient, i.e. they
  # do not persist from one request to the next and must always be reopened
  # when used. A future improvement would be to support persistent
  # `Keep-Alive` connections.
  #
  # Connections are at any one time in one of the two states of {#close
  # closed} or {#open open} (see {#open?}). You do not generally need to
  # call {#close} explicitly.
  #
  # @example Opening a connection to a Sesame server (1)
  #   url  = RDF::URI.new("http://localhost:8080/openrdf-sesame")
  #   conn = RDF::Sesame::Connection.open(url)
  #   ...
  #   conn.close
  #
  # @example Opening a connection to a Sesame server (2)
  #   RDF::Sesame::Connection.open(url) do |conn|
  #     ...
  #   end
  #
  # @example Performing an HTTP GET on a Sesame server
  #   RDF::Sesame::Connection.open(url) do |conn|
  #     conn.get("/openrdf-sesame/protocol") do |response|
  #       version = response.body.to_i
  #     end
  #   end
  #
  # @see http://ruby-doc.org/core/classes/Net/HTTP.html
  class Connection
    # @return [RDF::URI]
    attr_reader :url

    # @return [Hash{Symbol => Object}]
    attr_reader :options

    # @return [Hash{String => String}]
    attr_reader :headers

    # @return [Boolean]
    attr_reader :connected
    alias_method :connected?, :connected
    alias_method :open?,      :connected

    ##
    # Opens a connection to a Sesame server.
    #
    # @param  [RDF::URI, #to_s]        url
    # @param  [Hash{Symbol => Object}] options
    # @yield  [connection]
    # @yieldparam [Connection]
    # @return [Connection]
    def self.open(url, options = {}, &block)
      self.new(url, options) do |conn|
        if conn.open(options) && block_given?
          case block.arity
            when 1 then block.call(conn)
            else conn.instance_eval(&block)
          end
        else
          conn
        end
      end
    end

    ##
    # Initializes this connection.
    #
    # @param  [RDF::URI, #to_s]        url
    # @param  [Hash{Symbol => Object}] options
    # @yield  [connection]
    # @yieldparam [Connection]
    def initialize(url, options = {}, &block)
      @url = case url
        when Addressable::URI then url
        else Addressable::URI.parse(url.to_s)
      end

      @headers   = options.delete(:headers) || {}
      @options   = options
      @connected = false

      if block_given?
        case block.arity
          when 1 then block.call(self)
          else instance_eval(&block)
        end
      end
    end

    ##
    # Returns `true` unless this is an HTTPS connection.
    #
    # @return [Boolean]
    def insecure?
      !secure?
    end

    ##
    # Returns `true` if this is an HTTPS connection.
    #
    # @return [Boolean]
    def secure?
      scheme == :https
    end

    ##
    # Returns `:http` or `:https` to indicate whether this is an HTTP or
    # HTTPS connection, respectively.
    #
    # @return [Symbol]
    def scheme
      url.scheme.to_s.to_sym
    end

    ##
    # Returns the host name for this connection.
    #
    # @return [String]
    def host
      url.host.to_s
    end

    alias_method :hostname, :host

    ##
    # Returns the port number for this connection.
    #
    # @return [Integer]
    def port
      url.port.to_i
    end

    ##
    # Establishes the connection to the Sesame server.
    #
    # @param  [Hash{Symbol => Object}] options
    # @yield  [connection]
    # @yieldparam [Connection] connection
    # @raise  [TimeoutError] if the connection could not be opened
    # @return [void]
    def open(options = {}, &block)
      unless connected?
        # TODO: support persistent connections
        @connected = true
      end

      if block_given?
        result = block.call(self)
        close
        result
      else
        self
      end
    end

    alias_method :open!, :open

    ##
    # Closes the connection to the Sesame server.
    #
    # @return [void]
    def close
      if connected?
        # TODO: support persistent connections
        @connected = false
      end
    end

    alias_method :close!, :close

    ##
    # Performs an HTTP GET request for the given Sesame `path`.
    #
    # @param  [String, #to_s]          path
    # @param  [Hash{String => String}] headers
    # @yield  [response]
    # @yieldparam [Net::HTTPResponse] response
    # @return [Net::HTTPResponse]
    def get(path, headers = {}, &block)
      Net::HTTP.start(host, port) do |http|
        response = http.get(path.to_s, @headers.merge(headers))
        if block_given?
          block.call(response)
        else
          response
        end
      end
    end

    ##
    # Performs an HTTP POST request for the given Sesame `path`.
    #
    # @param  [String, #to_s]          path
    # @param  [Hash{String => String}] headers
    # @yield  [response]
    # @yieldparam [Net::HTTPResponse] response
    # @return [Net::HTTPResponse]
    def post(path, headers = {}, &block)
      # TODO
    end

    ##
    # Performs an HTTP PUT request for the given Sesame `path`.
    #
    # @param  [String, #to_s]          path
    # @param  [Hash{String => String}] headers
    # @yield  [response]
    # @yieldparam [Net::HTTPResponse] response
    # @return [Net::HTTPResponse]
    def put(path, headers = {}, &block)
      # TODO
    end

    ##
    # Performs an HTTP DELETE request for the given Sesame `path`.
    #
    # @param  [String, #to_s]          path
    # @param  [Hash{String => String}] headers
    # @yield  [response]
    # @yieldparam [Net::HTTPResponse] response
    # @return [Net::HTTPResponse]
    def delete(path, headers = {}, &block)
      # TODO
    end
  end
end
