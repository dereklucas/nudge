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
  attr_accessor :status_code, :response_body, :connection_delay
  attr_reader   :received_headers, :received_body

  def initialize
    @status_code = 200
    @response_body = nil
    @connection_delay = 0
  end

  def start(use_ssl: false)
    @tcp = TCPServerWithDelay.open(TEST_PORT)
    @tcp.test_server = self
    @tcp = switch_to_ssl(@tcp) if use_ssl
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

  def switch_to_ssl(socket)
    context = OpenSSL::SSL::SSLContext.new
    context.cert = OpenSSL::X509::Certificate.new(TEST_CERT)
    context.key = OpenSSL::PKey::RSA.new(TEST_KEY)

    OpenSSL::SSL::SSLServer.new(socket, context)
  end

  class TCPServerWithDelay < TCPServer
    attr_accessor :test_server

    def accept
      result = super
      sleep @test_server.connection_delay
      result
    end
  end

  TEST_CERT = "
-----BEGIN CERTIFICATE-----
MIIEBzCCAu+gAwIBAgIJAKcPiS/HQohBMA0GCSqGSIb3DQEBCwUAMIGZMQswCQYD
VQQGEwJVUzESMBAGA1UECAwJV2lzY29uc2luMRAwDgYDVQQHDAdNYWRpc29uMQ8w
DQYDVQQKDAZBcmNpdnIxFDASBgNVBAsMC0VuZ2luZWVyaW5nMRIwEAYDVQQDDAls
b2NhbGhvc3QxKTAnBgkqhkiG9w0BCQEWGmtldmluLm1jY29ubmVsbEBhcmNpdnIu
Y29tMB4XDTE2MDQyNzE1NTMwM1oXDTE3MDQyNzE1NTMwM1owgZkxCzAJBgNVBAYT
AlVTMRIwEAYDVQQIDAlXaXNjb25zaW4xEDAOBgNVBAcMB01hZGlzb24xDzANBgNV
BAoMBkFyY2l2cjEUMBIGA1UECwwLRW5naW5lZXJpbmcxEjAQBgNVBAMMCWxvY2Fs
aG9zdDEpMCcGCSqGSIb3DQEJARYaa2V2aW4ubWNjb25uZWxsQGFyY2l2ci5jb20w
ggEiMA0GCSqGSIb3DQEBAQUAA4IBDwAwggEKAoIBAQCwf/U4OpzAr8M7AM6glqPV
lbFrCiLHQvfIhSxbKTX7peRm6UBtGDfKaA2EGvyoOcr6pBn38wAZ6nkggw+KdBwH
5G98INALWuIvrZLYwA2FtIroEwBsa6QdkZsnzSwQejPHYJ4LxihMsckpjtLHTL+b
sF7N0xTGCH1STSBN4QpI8aigPy5qPH5TLpk8qcDkcahv31os+SyWYeKqyYmkScFo
g+OeMj2Dzeskng9CpQJR9Oh0uWHFLZmxfyEJSumeeaFf9LcjCGolZj6jgVoMZHSZ
O+GQXeC67z1InjjYQg/oiHlcw1MGRErDtgyfw+zKTT7NL+6/QTsB1VrzbwVVaSXz
AgMBAAGjUDBOMB0GA1UdDgQWBBT9p+pMvzjfzsbNGzo3HQvY/3VMxTAfBgNVHSME
GDAWgBT9p+pMvzjfzsbNGzo3HQvY/3VMxTAMBgNVHRMEBTADAQH/MA0GCSqGSIb3
DQEBCwUAA4IBAQBaR/V3c/IwS/yXmIoe3rSlGI9p4JBXJpSQ9TE+76fPrE8Rh7yr
9MHiDXUXfZcknOa1CMEA1lMT04kMcjUJ2EhAJDwOFoQWY15V5KrVs2duSmvuOc9J
tEYw8ItVNPRtxVLYvE5sodcSTZv5P+mkve//7AZG7yXKqT820iee9ZwNxXzkh1oi
Zx/sE+hlLuyMGlq2RjkajpZxifl+BY1l5atcd/JHNfyuVaBeZAtZ0kxc7cZnICLC
qX3oPggxhxbOvMpaUxna7aSzbU+bLAXiqKfa/viknndb6J/wwLI9iyYgHX7Kvt2t
173KPjwwXonqUz57t+a4wMpeA47YjFUVHBRK
-----END CERTIFICATE-----
  "

  TEST_KEY = "
-----BEGIN PRIVATE KEY-----
MIIEvgIBADANBgkqhkiG9w0BAQEFAASCBKgwggSkAgEAAoIBAQCwf/U4OpzAr8M7
AM6glqPVlbFrCiLHQvfIhSxbKTX7peRm6UBtGDfKaA2EGvyoOcr6pBn38wAZ6nkg
gw+KdBwH5G98INALWuIvrZLYwA2FtIroEwBsa6QdkZsnzSwQejPHYJ4LxihMsckp
jtLHTL+bsF7N0xTGCH1STSBN4QpI8aigPy5qPH5TLpk8qcDkcahv31os+SyWYeKq
yYmkScFog+OeMj2Dzeskng9CpQJR9Oh0uWHFLZmxfyEJSumeeaFf9LcjCGolZj6j
gVoMZHSZO+GQXeC67z1InjjYQg/oiHlcw1MGRErDtgyfw+zKTT7NL+6/QTsB1Vrz
bwVVaSXzAgMBAAECggEBAKKKlIfd4nHI66Aw1Bkr4WFW4/bRdMnQsGQn0Ht7bk17
ruXfNQfC3841GQ1p1PgPkRBVg9zGGnfDaR051VwKJa5W/xxvE2kBn3+M98lIxKs3
YxzqMt+mGZNpflufJU9fWsPoBGSPbpmCuODeuNn1ohd8yzH9jAn7032xrWhLMK+O
5ImtLR7TQatntYFrMk7vhqgXpCwvaj2JXqR8VyJFzBp+o+4q/6vPnfCJVojUPIe5
a6rPn+yAolMc4UZ+Kd+DFMupHD7REGegHfsvjADPug3rUGbMxynuaCwLMS0S9WRw
cVfyPyeFzkInjiK3ZMzl7ZSmsRQfgCHKaiD9ixT1PYECgYEA5rZNMmCS9srZV4oS
nuMuWH8bw+cB+vbYAxpuGr1F4/vZ9Pz/wQt4agiQKbH7VBuliipvMNe9Oib/DCH6
sOi477PcqwnmxlKGZ/AyEZkXdXN2VdQzkOBap5j2E4qFhOMhoDBycNNOOYjp0LBF
XfKt0/o3j+Y2AushnzTHXWlJlGECgYEAw9h6uSFNtEvIMVh2A+fbMLCPr2bKBuw8
0aKMtKqThOz2OHKg58EzLpm8tzYzyoM2ELWoQCm11twFASpmy0KSNnu9WCsGjDHi
ibwMqtAB2RwprDM288Gdrahy37+Dggo0OJU6/fdAdUgb3Y7P+V2YmmmxBvl7P4xp
7d3S6XHyGtMCgYEAsGSzkw/JbY1cLRTw9bAmkBzm4potpm6ya3T6t9D8rbmyRCBn
fnZBo3hWmLpuuTjGEWQuTT61e8+y8tjL7hSQyRxQXCke24TfJHq+HTxadj9IO4kZ
v+v5A+jsQ7aGLTrnS62e4ep9BXpLonYTIyhXhRnq/0d5BjQ2KZ5Vy3KjgiECgYBp
+AenhnqqFNs0wB3TTTBP7ylACklEZ60c7WxfEXES2rj7oCKqY+KS04LGS6DIcijd
770jQq5unMxkbhIC53l/24J/Y4B+eTuPtV3RSw3E8TUnROr2CAyOe3f004aP5X+O
IkkyRAfvrd3OC0lDL76zxn6QPIvQveRPXdiSkiIjGwKBgFSTPGY15v4TSnQGkOJH
dZAX97aG42UhEIMAxeX4+7P4RoBJ1XPOqMlgHKO6FJJlpkHr2CaFvSphplyvSwUq
4fBVFrXFNIHtb/K+7RhuTvlylFNH9cK73XvCTwGVf5PeiFIvo39RjRobB7sJBAcf
qsZuENv4G4lvspBMnFMuNm2L
-----END PRIVATE KEY-----
  "
end
