require 'openssl'

module Nudge
  class Certificate
    attr_reader :context

    def initialize(pem_path, passphrase)
      data = read_pem(pem_path)
      key = OpenSSL::PKey::RSA.new(data, passphrase)
      cert = OpenSSL::X509::Certificate.new(data)
      @context = create_context(key, cert)
    end


    private

    def read_pem(pem_path)
      return File.read(pem_path)
    end

    def create_context(key, cert)
      context = OpenSSL::SSL::SSLContext.new
      context.key = key
      context.cert = cert
      context
    end
  end
end
