#!/usr/bin/env ruby

require 'flickraw'
require 'optparse'
require 'open-uri'

module Flickpaper
  VERSION = File.read(File.expand_path('../version', __FILE__)).to_s.strip.split('.').map(&:to_i)
  API_KEY = '4027d0c82688548d5a72a2e6a37220f4'
  SHARED_SECRET = '61f001fe9022e85b'

  def self.init
    FlickRaw.api_key = API_KEY
    FlickRaw.shared_secret = SHARED_SECRET
  end

  def self.parse_opts(opts)
    options = {}
    opt_parser = OptionParser.new do |opts|
      opts.banner = "Usage: #{$0} [options]"
      opts.on('-v', '--verbose', 'Verbose') do |verbose|
        options[:verbose] = verbose
      end
      opts.on_tail("--version", "Show version") do
        puts Flickpaper::VERSION.map(&:to_s).join('.')
        exit
      end
    end
    opt_parser.parse!(opts)
    [opts, options]
  end

  # date (Optional)
  #   A specific date, formatted as YYYY-MM-DD, to return interesting photos for.
  # extras (Optional)
  #   A comma-delimited list of extra information to fetch for each returned record. Currently supported fields are: description, license, date_upload, date_taken, owner_name, icon_server, original_format, last_update, geo, tags, machine_tags, o_dims, views, media, path_alias, url_sq, url_t, url_s, url_q, url_m, url_n, url_z, url_c, url_l, url_o
  # per_page (Optional)
  #   Number of photos to return per page. If this argument is omitted, it defaults to 100. The maximum allowed value is 500.
  # page (Optional)
  #   The page of results to return. If this argument is omitted, it defaults to 1.
  def self.interesting(options = {})
    flickr.interestingness.getList(options)
  end

  def self.infos(list)
    list.map do |photo|
      flickr.photos.getInfo(photo_id: photo['id'])
    end
  end

  def self.sizes(list)
    list.map do |photo|
      flickr.photos.getSizes(photo_id: photo['id'])
    end
  end

  def self.sort_infos(infos)
    sort_vals = infos.inject({}) do |sort_vals, info|
      sort_vals[info['id']] = (info['views'].to_f ** 0.5) * (info['comments'].to_f ** 0.5)
      sort_vals
    end

    infos.sort do |x,y|
      sort_vals[y['id']] <=> sort_vals[x['id']]
    end
  end

  def self.save_file(url, dst)
    File.open(dst, "wb") do |saved_file|
      open(url, "rb") do |read_file|
        saved_file.write(read_file.read)
      end
    end
  end

  def self.set_wallpaper(path)
    bash = <<-EOBASH
      sessionfile=`find "${HOME}/.dbus/session-bus/" -type f`
      eval `cat ${sessionfile}`
      export DBUS_SESSION_BUS_ADDRESS \
             DBUS_SESSION_BUS_PID \
             DBUS_SESSION_BUS_WINDOWID

      gsettings set org.gnome.desktop.background picture-uri "file://#{path}"
    EOBASH
    system(bash)
  end
end

if __FILE__ == $0
  arguments, options = Flickpaper.parse_opts(ARGV.dup)
  Flickpaper.init

  list = Flickpaper.interesting
  infos = Flickpaper.sort_infos(Flickpaper.infos(list))
  sorted_list = infos.map do |info|
    list.detect { |photo| photo['id'] == info['id'] }
  end
  sizes = Flickpaper.sizes(sorted_list)

  idx = nil
  url = nil

  (0...(sizes.length)).each do |i|
    if my_size = sizes[i].detect { |s| s['label'] == "Large 2048" }
      idx = i
      url = my_size['source']
      break
    end
  end

  my_photo = sorted_list[idx]
  my_info = infos[idx]

  dst = File.join(ENV['HOME'], '.flickr.jpg')
  Flickpaper.save_file(url, dst)
  Flickpaper.set_wallpaper(dst)
end
