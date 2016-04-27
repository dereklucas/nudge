require 'spec_helper'
require 'support/test_http2_server'

include Nudge

RSpec.describe SSLSocket do
  let(:ssl_context) { create_test_context }
  let(:certificate) { double(:certificate, context: ssl_context) }
  let(:socket)      { SSLSocket.new('localhost', TEST_PORT, certificate) }
  let(:server)      { TestHTTP2Server.new }

  before do
    server.start(use_ssl: true)
  end

  after do
    server.stop
  end

  it "is not initially connected" do
    expect(socket).to_not be_connected
  end

  it "can connect without error" do
    expect {
      socket.connect
    }.to_not raise_error
  end

  it "has a connected? status" do
    socket.connect

    expect(socket).to be_connected
  end

  it "raises an exception on timeout" do
    server.connection_delay = 0.2
    socket.timeout_seconds = 0.1

    expect {
      socket.connect
    }.to raise_error(Nudge::ConnectionTimeoutError)
  end

  def create_test_context
    context = OpenSSL::SSL::SSLContext.new
    context.key = OpenSSL::PKey::RSA.new(TestHTTP2Server::TEST_KEY)
    context.cert = OpenSSL::X509::Certificate.new(TestHTTP2Server::TEST_CERT)
    context
  end
end
