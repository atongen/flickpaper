require 'flickpaper/version'

require 'flickraw'
require 'optparse'
require 'open-uri'
require 'rbconfig'

module Flickpaper
  API_KEY = '23005d9cf8cc185c1c2d17152d03d98b'
  SHARED_SECRET = 'a6e67612f607b407'

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

  def self.save_file(url, dst)
    File.open(dst, 'wb') do |saved_file|
      open(url, 'rb') do |read_file|
        saved_file.write(read_file.read)
      end
    end
  end

  def self.set_wallpaper(path)
    case os
    when :windows
      false
    when :macosx
      set_wallpaper_macosx(path)
    when :linux, :unix
      set_wallpaper_linux(path)
    else
      false
    end
  end

  def self.set_wallpaper_macosx(path)
    bash = <<-EOBASH
      tell application "Finder"
        set desktop picture to POSIX file "#{path}"
      end tell
    EOBASH
    system(bash)
  end

  def self.set_wallpaper_linux(path)
    dbus_launch = %w{ which dbus-launch }.to_s.strip
    if dbus_launch != ""
      # http://dbus.freedesktop.org/doc/dbus-launch.1.html
      bash = <<-EOBASH
        if [ -z "$DBUS_SESSION_BUS_ADDRESS" ]; then
          # if not found, launch a new one
          eval `dbus-launch --sh-syntax`
        fi

        gsettings set org.gnome.desktop.background picture-uri "file://#{path}"
      EOBASH
      system(bash)
    else
      false
    end
  end

  def self.get_ids(file)
    File.file?(file) ? Marshal.load(File.read(file)) : []
  end

  def self.put_ids(file, ids)
    File.open(file, 'wb') { |f| f << Marshal.dump(ids) }
    ids
  end

  def self.os
    host_os = RbConfig::CONFIG['host_os']
    case host_os
    when /mswin|msys|mingw|cygwin|bccwin|wince|emc/
      :windows
    when /darwin|mac os/
      :macosx
    when /linux/
      :linux
    when /solaris|bsd/
      :unix
    end
  end

  def self.run!
    arguments, options = Flickpaper.parse_opts(ARGV.dup)
    if options[:verbose]
      puts "Initializing flickr api"
    end
    Flickpaper.init

    if options[:verbose]
      puts "Getting interesting list"
    end
    list = Flickpaper.interesting(per_page: 25)
    ids = Flickpaper.get_ids(options[:dump])
    list = list.select { |l| !ids.include?(l['id']) }

    idx = nil
    url = nil

    if options[:verbose]
      puts "Selecting large photo"
    end
    (0...(list.length)).each do |i|
      size = flickr.photos.getSizes(photo_id: list[i]['id'])
      if my_size = size.detect { |s| s['label'] == "Large 2048" }
        idx = i
        url = my_size['source']
        break
      end
    end

    if idx
      my_photo = list[idx]

      Flickpaper.save_file(url, options[:image])
      result = Flickpaper.set_wallpaper(options[:image])
      if result
        if options[:verbose]
          puts "Set photo #{my_photo['id']} as wallpaper"
        end
        Flickpaper.put_ids(options[:dump], ids<<my_photo['id'])
      else
        if options[:verbose]
          puts "Unable to set photo #{my_photo['id']} as wallpaper"
        end
      end
    else
      if options[:verbose]
        puts "Unable to find photo for wallpaper"
      end
    end
  end
end
