#!/usr/bin/env ruby
require 'socket'
require 'websocket/driver'

class EchoServer

  RECV_SIZE = 1024

  HOST = 'localhost'

  attr_reader :server

  def initialize(port = nil)
    @server = start_server port
  end

  def start_server(port)
    ::TCPServer.open(HOST, port || 0)
  end

  def port
    server.addr[1]
  end

  def handle(socket)
    driver = ::WebSocket::Driver.server(socket)
    driver.on(:connect) { driver.start }
    driver.on(:message) { |e| driver.text e.data }
    driver.on(:close)   { puts "Connection with #{socket.addr[2]} closed." }
    loop do
      IO.select([socket], [], [], 30) or raise Errno::EWOULDBLOCK
      data = socket.recv(RECV_SIZE)
      break if data.empty?
      driver.parse data
    end
  end

  def listen
    loop do
      client = server.accept
      puts "Accepted connection from #{client.addr[2]}"
      Thread.new { handle client }
    end
  end

end

server = EchoServer.new
puts "EchoServer is listening on #{server.port}"
server.listen
