require 'flickpaper/version'

require 'flickraw'
require 'optparse'
require 'open-uri'
require 'rbconfig'
require 'logger'

module Flickpaper
  API_KEY = '23005d9cf8cc185c1c2d17152d03d98b'
  # Shared secret not required?
  SHARED_SECRET = ''

  SIZES = %w{
    Square
    Large\ Square
    Thumbnail
    Small
    Small\ 320
    Medium
    Medium\ 640
    Medium\ 800
    Large
    Large\ 1600
    Large\ 2048
    Original
  }

  def self.init
    FlickRaw.api_key = API_KEY
    FlickRaw.shared_secret = SHARED_SECRET
  end

  def self.parse_opts(opts)
    options = {
      dump: File.join(ENV['HOME'], '.flickpaper.dump'),
      image: get_default_image_path,
      log: nil,
      per_page: 100,
      date: nil,
      page: 1,
      size: 'Large 2048'
    }
    opt_parser = OptionParser.new do |opts|
      opts.banner = "Usage: $ #{File.basename($0)} [options]"
      opts.on('-d', '--dump PATH', "Dump file for used photo ids. Default: #{options[:dump]}") do |dump|
        options[:dump] = dump
      end
      opts.on('-i', '--image PATH', "Where to store the downloaded image. Default: #{options[:image]}") do |image|
        options[:image] = image
      end
      opts.on('-l', '--log PATH', "Path to log file. Default: STDOUT") do |log|
        options[:log] = log
      end
      opts.on('-p', '--per-page PER_PAGE', "Number of interesting photos per page in flickr api call. Default: #{options[:per_page]}") do |per_page|
        options[:per_page] = per_page
      end
      opts.on('--date DATE', "A specific date, formatted as YYYY-MM-DD, to return interesting photos for. Default: null (most recent)") do |date|
        options[:date] = date
      end
      opts.on('--page PAGE', "The page of results to return. Default: #{options[:page]}") do |page|
        options[:page] = page
      end
      opts.on('-s', '--size SIZE', "Minimum acceptable image size. Default: #{options[:size]}") do |size|
        options[:size]= size
      end
      opts.on('-v', '--verbose', 'Be verbose.') do |verbose|
        options[:verbose] = verbose
      end
      opts.on('--sizes', "Print sizes and exit.") do |sizes|
        puts SIZES.join(', ')
        exit 0
      end
      opts.on_tail("--version", "Show version and exit.") do
        puts Flickpaper::VERSION
        exit 0
      end
    end
    opt_parser.parse!(opts)
    [opts, options]
  end

  def self.save_file(url, dst)
    File.open(dst, 'wb') do |saved_file|
      open(url, 'rb') do |read_file|
        saved_file.write(read_file.read)
      end
    end
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

  # http://apple.stackexchange.com/questions/200125/how-to-create-an-osx-application-to-wrap-a-call-to-a-shell-script
  # http://www.hccp.org/command-line-os-x.html
  # http://osxdaily.com/2015/08/28/set-wallpaper-command-line-macosx/
  def self.set_wallpaper_macosx(path)
    osascript = %x{ which osascript }.to_s.strip
    if osascript == ""
      false
    else
      bash = <<-EOBASH
        #{osascript} -e 'tell application "Finder" to set desktop picture to POSIX file "#{path}"'
      EOBASH
      system(bash)
    end
  end

  def self.set_wallpaper_linux(path)
    dbus_launch = %x{ which dbus-launch }.to_s.strip
    gsettings = %x{ which gsettings }.to_s.strip
    if dbus_launch == "" || gsettings == ""
      false
    else
      # http://dbus.freedesktop.org/doc/dbus-launch.1.html
      bash = <<-EOBASH
        if [ -z "$DBUS_SESSION_BUS_ADDRESS" ]; then
          # if not found, launch a new one
          eval `#{dbus_launch} --sh-syntax`
        fi

        #{gsettings} set org.gnome.desktop.background picture-uri "file://#{path}"
      EOBASH
      system(bash)
    end
  end

  def self.get_default_image_path
    case os
    when :windows
      false
    when :macosx
      home_tmp = File.join(ENV['HOME'], 'tmp')
      if File.directory?(home_tmp)
        File.join(home_tmp, "flickpaper-#{ENV['USER']}.jpg")
      else
        File.join('/tmp', "flickpaper-#{ENV['USER']}.jpg")
      end
    when :linux, :unix
      File.join(ENV['HOME'], '.flickpaper.jpg')
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

  def self.run!
    arguments, options = Flickpaper.parse_opts(ARGV.dup)
    log = Logger.new(options[:log] ? options[:log] : STDOUT)
    log.level = options[:verbose] ? Logger::INFO : Logger::ERROR

    size_idx = SIZES.index(options[:size])
    if size_idx.nil? || size_idx < 0
      log.error("Invalid size argument: #{options[:size]}.\nPlease select from: #{SIZES.join(', ')}.")
      exit 1
    end

    Flickpaper.init

    opts = options.select { |k,v| [:page, :per_page, :date].include?(k) && !v.nil? }
    log.info("Getting interesting list: #{opts.inspect}")
    begin
      # date (Optional)
      #   A specific date, formatted as YYYY-MM-DD, to return interesting photos for.
      # extras (Optional)
      #   A comma-delimited list of extra information to fetch for each returned record. Currently supported fields are: description, license, date_upload, date_taken, owner_name, icon_server, original_format, last_update, geo, tags, machine_tags, o_dims, views, media, path_alias, url_sq, url_t, url_s, url_q, url_m, url_n, url_z, url_c, url_l, url_o
      # per_page (Optional)
      #   Number of photos to return per page. If this argument is omitted, it defaults to 100. The maximum allowed value is 500.
      # page (Optional)
      #   The page of results to return. If this argument is omitted, it defaults to 1.
      list = flickr.interestingness.getList(opts)
    rescue FlickRaw::FailedResponse => e
      log.error("Flickr API error: #{e.message}")
      exit 1
    end

    ids = Flickpaper.get_ids(options[:dump])
    list = list.select { |l| !ids.include?(l['id']) }

    idx = nil
    url = nil

    log.info("Selecting large photo")
    (0...(list.length)).each do |i|
      begin
        size = flickr.photos.getSizes(photo_id: list[i]['id'])
      rescue FlickRaw::FailedResponse => e
        log.error("Flickr API error: #{e.message}")
        exit 1
      end
      my_size = size.detect do |s|
        my_size_idx = SIZES.index(s['label'])
        !my_size_idx.nil? && my_size_idx >= size_idx
      end
      if my_size
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
        log.info("Set photo #{my_photo['id']} as wallpaper")
        Flickpaper.put_ids(options[:dump], ids<<my_photo['id'])
      else
        log.error("Unable to set photo #{my_photo['id']} as wallpaper")
      end
    else
      log.error("Unable to find photo for wallpaper")
    end
  end
end
