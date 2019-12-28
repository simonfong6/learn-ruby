#!/usr/bin/env ruby

=begin
A simple web server made with code from this guide:
https://www.rubyguides.com/2016/08/build-your-own-web-server/
=end
require 'socket'

server  = TCPServer.new('localhost', 8080)

def parse(request)
  method, path, version = request.lines[0].split

  {
    path: path,
    method: method,
    headers: parse_headers(request)
  }
end

def normalize(header)
  header.gsub(":", "").downcase.to_sym
end

def parse_headers(request)
  headers = {}

  request.lines[1..-1].each do |line|
    return headers if line == "\r\n"

    header, value = line.split
    header        = normalize(header)

    headers[header] = value
  end

end

SERVER_ROOT = "static/"

def prepare_response(request)
  if request.fetch(:path) == "/"
    respond_with(SERVER_ROOT + "index.html")
  else
    respond_with(SERVER_ROOT + request.fetch(:path))
  end
end

def respond_with(path)
  if File.exists?(path)
    send_ok_response(File.binread(path))
  else
    send_file_not_found
  end
end

def send_ok_response(data)
  Response.new(code: 200, data: data)
end
  
def send_file_not_found
  Response.new(code: 404)
end

class Response
  attr_reader :code, :data

  def initialize(code:, data: "")
    @response =
    "HTTP/1.1 #{code}\r\n" +
    "Content-Length: #{data.size}\r\n" +
    "\r\n" +
    "#{data}\r\n"
  end
  def send(client)
    client.write(@response)
  end
end

loop {
  client  = server.accept
  request = client.readpartial(2048)
  request  = parse(request)
  response = prepare_response(request)
  puts "#{client.peeraddr[3]} #{request.fetch(:path)} - #{response.code}"
  response.send(client)
  client.close
}