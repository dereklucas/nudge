require 'socket'
require 'http/2'

TEST_PORT = 55555

class TestSocket
  def connected?
    @tcp && @tcp.connected?
  end

  def connect
    unless connected?
      @tcp = TCPSocket.new('localhost', TEST_PORT)
    end
  end

  def disconnect
    @tcp && @tcp.close; @tcp = nil
  end

  def <<(data)
    @tcp << data
    @tcp.flush
  end

  def read(size)
    @tcp.read_nonblock(size) unless @tcp.eof?
  end
end

class TestHTTP2Server
  attr_accessor :status_code, :response_body
  attr_reader   :received_headers, :received_body

  def initialize
    @status_code = 200
    @response_body = nil
  end

  def start
    @tcp = TCPServer.open(TEST_PORT)
    listen_for_connections
  end

  def stop
    @tcp.close
  end

  def received_header(name)
    header = @received_headers.detect { |h| h.first == name }
    header.last if header
  end

  private

  def listen_for_connections
    Thread.new do
      sock = @tcp.accept
      finished = false

      http2 = HTTP2::Server.new
      http2.on(:frame) do |data|
        sock.write(data)
      end

      http2.on(:stream) do |stream|
        stream.on(:headers) do |h|
          @received_headers = h
        end

        stream.on(:data) do |data|
          @received_body = data
        end

        stream.on(:half_close) do
          respond_to_stream(stream)
          finished = true
        end
      end

      while !finished && !sock.closed? && !sock.eof?
        data = sock.readpartial(1024)
        http2 << data
      end
    end
  end

  def respond_to_stream(stream)
    if @response_body
      respond_to_stream_as_body(stream)
    else
      respond_to_stream_as_header(stream)
    end
  end

  def respond_to_stream_as_header(stream)
    stream.headers({ ':status' => @status_code.to_s }, end_stream: true)
  end

  def respond_to_stream_as_body(stream)
    stream.headers({ ':status'        => @status_code.to_s,
                     'content-length' => @response_body.bytesize.to_s })
    stream.data(@response_body)
  end
end
