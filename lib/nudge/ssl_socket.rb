module Nudge
  class ConnectionTimeoutError < RuntimeError; end

  class SSLSocket
    attr_reader :host, :port
    attr_accessor :timeout_seconds

    DEFAULT_TIMEOUT_SECONDS = 3

    def initialize(host, port, certificate)
      @host, @port, @certificate = host, port, certificate
      @timeout_seconds = DEFAULT_TIMEOUT_SECONDS
    end

    def connected?
      @ssl && @ssl.ssl_version && !@ssl.closed?
    end

    def connect
      unless connected?
        disconnect

        @tcp = TCPSocket.new(@host, @port)
        @ssl = OpenSSL::SSL::SSLSocket.new(@tcp, @certificate.context)
        @ssl.hostname = @host

        connect_socket
      end
    end

    def disconnect
      @ssl && @ssl.close; @ssl = nil
      @tcp && @tcp.close; @tcp = nil
    end

    def <<(data)
      @ssl << data
      @ssl.flush
    end

    def read(size)
      @ssl.read_nonblock(size) unless @ssl.eof?
    end

    private

    def connect_socket
      while !connected?
        begin
          result = @ssl.connect_nonblock
        rescue IO::WaitReadable
          wait_for_ready_or_timeout([@ssl], nil)
        rescue IO::WaitWritable
          wait_for_ready_or_timeout(nil, [@ssl])
        end
      end
    end

    def wait_for_ready_or_timeout(read, write)
      unless IO.select(read, write, nil, @timeout_seconds)
        disconnect
        raise ConnectionTimeoutError.new
      end
    end
  end
end
