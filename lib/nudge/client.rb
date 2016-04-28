require 'nudge/transport'

module Nudge
  class Client

    PRODUCTION_ENDPOINT   = 'api.push.apple.com'
    DEVELOPMENT_ENDPOINT  = 'api.development.push.apple.com'
    SERVICE_PORT          = 443

    attr_reader :transport

    def initialize(certificate, production: true, topic: nil)
      @socket     = create_socket(certificate, production)
      @transport  = create_transport(@socket)
      @topic      = topic
    end

    def send(token, payload)
      payload = payload.to_json
      headers = build_headers
      response = @transport.post('/3/device/' + token, payload, headers)
    end

    private

    def create_socket(certificate, production)
      host = production ? PRODUCTION_ENDPOINT : DEVELOPMENT_ENDPOINT
      port = SERVICE_PORT
      Nudge::SSLSocket.new(host, port, certificate)
    end

    def create_transport(socket)
      Transport.new(socket)
    end

    def build_headers
      headers = {}
      headers['apns-topic'] = @topic if @topic
      headers
    end
  end
end
