module Nudge
  class SSLSocket
    attr_reader :host, :port

    def initialize(host, port, certificate)
      @host, @port, @certificate = host, port, certificate
    end

    def connected?
      @ssl && @ssl.state == :connected
    end

    def connect
      unless connected?
        @tcp = TCPSocket.new(@host, @port)
        @ssl = OpenSSL::SSL::SSLSocket.new(@tcp, @certificate.context)
        @ssl.hostname = @host
        @ssl.connect
      end
    end

    def disconnect
      @ssl.try(:close); @ssl = nil
      @tcp.try(:close); @tcp = nil
    end

    def <<(data)
      @ssl << data
      @ssl.flush
    end

    def read(size)
      @ssl.read_nonblock(size) unless @ssl.eof?
    end
  end
end
