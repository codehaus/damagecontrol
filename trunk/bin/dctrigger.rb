#!/usr/bin/env ruby

require 'xmlrpc/client'

url = ARGV[0]
project_name = ARGV[1]

puts "Requesting build of project '#{project_name}' over #{url}"
client = XMLRPC::Client.new2(url)
build = client.proxy("build")
# old syntax
result = build.trig(project_name, Time.now.utc.strftime("%Y%m%d%H%M%S"))
#result = build.request(project_name)
puts result

