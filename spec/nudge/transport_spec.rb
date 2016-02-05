require 'spec_helper'
require 'support/test_http2_server'
require 'json'

include Nudge

RSpec.describe Transport do
  let(:socket)    { TestSocket.new }
  let(:server)    { TestHTTP2Server.new }

  let(:transport) { Transport.new(socket) }

  before do
    server.start
  end

  after do
    server.stop
  end

  context "posting a request" do
    context "headers" do
      before do
        transport.post('/test', 'body', { 'custom' => 'value' })
      end

      it "sends the path header" do
        expect(server.received_header(':path')).to eq('/test')
      end

      it "sends the custom headers" do
        expect(server.received_header('custom')).to eq('value')
      end

      it "sends a content-length header" do
        expect(server.received_header('content-length')).to eq('4')
      end
    end

    context "body" do
      before do
        transport.post('/test', 'body', { 'custom' => 'value' })
      end

      it "sends the body" do
        expect(server.received_body).to eq('body')
      end
    end

    context "when the server returns success" do
      before do
        server.status_code = 200
      end

      let(:response) { transport.post('/test', '', {}) }

      it "returns a successful response" do
        expect(response.success).to be true
      end

      it "returns no message" do
        expect(response.message).to be_nil
      end
    end

    context "when the server returns an error" do
      before do
        server.status_code = 400
        server.response_body = {
          "payload" => { "reason": "it's broken" }
        }.to_json
      end

      let(:response) { transport.post('/test', '', {}) }

      it "returns a failure response" do
        expect(response.success).to be false
      end

      it "returns the payload reason as the message" do
        expect(response.message).to eq("it's broken")
      end
    end
  end
end
