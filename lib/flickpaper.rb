require "flickpaper/version"

require 'flickraw'
require 'optparse'
require 'open-uri'

module Flickpaper
  API_KEY = '4027d0c82688548d5a72a2e6a37220f4'
  SHARED_SECRET = '61f001fe9022e85b'

  def self.init
    FlickRaw.api_key = API_KEY
    FlickRaw.shared_secret = SHARED_SECRET
  end

  def self.parse_opts(opts)
    options = {
      dump: File.join(ENV['HOME'], '.flickpaper.dump'),
      image: File.join(ENV['HOME'], '.flickpaper.jpg')
    }
    opt_parser = OptionParser.new do |opts|
      opts.banner = "Usage: $ #{File.basename($0)} [options]"
      opts.on('-d', '--dump [PATH]', "Dump file for used photo ids. Default: #{options[:dump]}") do |dump|
        options[:dump] = dump
      end
      opts.on('-i', '--image [PATH]', "Where to store the downloaded image. Default: #{options[:image]}") do |image|
        options[:image] = image
      end
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
    File.open(dst, 'wb') do |saved_file|
      open(url, 'rb') do |read_file|
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

  def self.get_ids(file)
    File.file?(file) ? Marshal.load(File.read(file)) : []
  end

  def self.put_ids(file, ids)
    File.open(file, 'wb') { |f| f << Marshal.dump(ids) }
    ids
  end

  def self.run!
    arguments, options = Flickpaper.parse_opts(ARGV.dup)
    Flickpaper.init

    list = Flickpaper.interesting
    ids = Flickpaper.get_ids(options[:dump])
    list = list.select { |l| !ids.include?(l['id']) }
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

    if idx
      my_photo = sorted_list[idx]
      my_info = infos[idx]

      Flickpaper.save_file(url, options[:image])
      Flickpaper.set_wallpaper(options[:image])
      Flickpaper.put_ids(options[:dump], ids<<my_photo['id'])
    end
  end
end
