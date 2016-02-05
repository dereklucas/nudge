require 'nudge/transport'

module Nudge
  class Client

    PRODUCTION_ENDPOINT   = 'api.push.apple.com'
    DEVELOPMENT_ENDPOINT  = 'api.development.push.apple.com'
    SERVICE_PORT          = 443

    attr_reader :transport

    def initialize(certificate, production: true)
      @transport = create_transport(certificate, production)
      @transport.connect
    end

    def send(token, payload)
      payload = payload.to_json
      headers = { }
      response = @transport.post('/3/device/' + token, payload, headers)
    end

    private

    def create_transport(certificate, production)
      host = production ? PRODUCTION_ENDPOINT : DEVELOPMENT_ENDPOINT
      port = SERVICE_PORT

      Transport.new(certificate, host, port)
    end
  end
end
