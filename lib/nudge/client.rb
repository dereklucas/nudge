require 'nudge/transport'

module Nudge
  class Client

    PRODUCTION_ENDPOINT   = 'api.push.apple.com'
    DEVELOPMENT_ENDPOINT  = 'api.development.push.apple.com'
    SERVICE_PORT          = 443

    attr_reader :transport

    def initialize(certificate, production: true)
      @socket     = create_socket(certificate, production)
      @transport  = create_transport(@socket)
    end

    def send(token, payload)
      payload = payload.to_json
      headers = { }
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
  end
end
