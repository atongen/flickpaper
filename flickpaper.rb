#!/usr/bin/env ruby

require 'flickraw'
require 'optparse'
require 'pp'

Version = [0,0,1]

options = {}
opt_parser = OptionParser.new do |opts|
  opts.banner = "Usage: #{$0} [options]"
  opts.on('-k', '--api-key KEY', 'flickr api key') do |key|
    options[:api_key] = key
  end
  opts.on('-s', '--api-secret SECRET', 'flickr api secret') do |secret|
    options[:api_secret] = secret
  end
  opts.on_tail("--version", "Show version") do
    puts Version.map(&:to_s).join('.')
    exit
  end
end
opts = ARGV.dup
opt_parser.parse!(opts)

if options[:api_key]
  FlickRaw.api_key = options[:api_key]
else
  puts opt_parser
  exit 1
end

if options[:api_secret]
  FlickRaw.shared_secret = options[:api_secret]
else
  puts opt_parser
  exit 1
end

list = flickr.interestingness.getList
puts list.length
puts
p = list.first
info = flickr.photos.getInfo(photo_id: p['id'])
puts info.class.name
puts 'info'
pp info
puts
sizes = flickr.photos.getSizes(photo_id: p['id'])
puts sizes.class.name
puts 'sizes'
pp sizes
puts
puts FlickRaw.url_b(info)
