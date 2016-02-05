require 'http/2'
require 'openssl'
require 'socket'
require 'json'
require 'nudge/ssl_socket'

module Nudge
  class Transport
    def initialize(socket)
      @socket = socket
    end

    def connected?
      @http2 && @http2.state == :connected
    end

    def connect
      unless connected?
        @socket.connect

        @http2 = HTTP2::Client.new
        @http2.on(:frame) do |frame|
          @socket << frame
        end
      end
    end

    def disconnect
      @socket.disconnect
    end

    def post(path, payload, headers)
      connect

      response_headers = []
      response_body = nil
      stream = @http2.new_stream
      reading = true

      stream.on(:close) do
        reading = false
      end

      stream.on(:headers) do |h|
        response_headers = h
      end

      stream.on(:data) do |d|
        response_body = d
      end

      headers = headers.dup
      headers['content-length'] = payload.length.to_s
      headers[':method'] = 'POST'
      headers[':path'] = path

      stream.headers(headers, end_stream: false)
      stream.data(payload)

      while reading && connected?# && !@socket.eof?
        data = @socket.read(1024)
        @http2 << data
      end

      status = response_headers.detect { |h| h.first == ":status" }.last
      success = (status == "200")
      payload = JSON.parse(response_body || "{}")["payload"]
      message = (payload || {})["reason"]

      return Response.new(success, message)
    end

    private

  end
end
