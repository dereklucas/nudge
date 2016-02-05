require 'spec_helper'
require 'json'

include Nudge

RSpec.describe Client do
  let(:certificate) { double(:certificate) }
  let(:transport)   { double(:transport, connect: nil, post: nil) }

  before do
    allow(Transport).to receive(:new).and_return(transport)
  end

  context "initializing" do
    context "when connecting to production (default)" do
      let!(:client) { Client.new(certificate) }

      it "creates a transport to the production endpoint" do
        expect(Transport).to have_received(:new) do |s|
          expect(s.host).to eq('api.push.apple.com')
          expect(s.port).to eq(443)
        end
      end
    end

    context "when connecting to development" do
      let!(:client) { Client.new(certificate, production: false) }

      it "creates a transport to the development endpoint" do
        expect(Transport).to have_received(:new) do |s|
          expect(s.host).to eq('api.development.push.apple.com')
          expect(s.port).to eq(443)
        end
      end
    end
  end

  context "sending messages" do
    let(:client)          { Client.new(certificate) }
    let(:message_payload) { { aps: { alert: 'Hello' } } }
    let(:token)           { "abcdef" }

    it "posts the payload to the transport" do
      client.send(token, message_payload)

      expect(transport).to have_received(:post) do |path, payload, headers|
        expect(path).to eq('/3/device/abcdef')
        expect(payload).to eq(message_payload.to_json)
      end
    end

    it "returns the response from the transport" do
      response = double(:response)
      allow(transport).to receive(:post).and_return(response)

      r = client.send(token, message_payload)
      expect(r).to eq(response)
    end
  end
end
