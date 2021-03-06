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

    def send(token, notification)
      headers = build_headers(notification.payload.delete(:collapse_id))
      payload = notification.to_json
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

    def build_headers(collapse = nil)
      headers = {}
      headers['apns-topic'] = @topic if @topic
      headers['apns-collapse-id'] = collapse.byteslice(0, 64) if collapse
      headers
    end
  end
end
