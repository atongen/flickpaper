# Flickpaper

A [Ruby Gem](https://rubygems.org/gems/flickpaper) and [Flickr App](https://www.flickr.com/services/apps/72157658406991003)
that sets your GNOME or OSX wallpaper to a recent interesting photo.

Does not (and will likely never) work under MS Windows.

## Installation

Install the gem:

```shell
$ gem install flickpaper
```

Or add this line to your application's Gemfile:

```ruby
gem 'flickpaper'
```

And then execute:

```shell
$ bundle
```

## Usage

```shell
Usage: $ flickpaper [options]
    -d, --dump [PATH]                Dump file for used photo ids. Default: $HOME/.flickpaper.dump
    -i, --image [PATH]               Where to store the downloaded image. Default: $HOME/.flickpaper.jpg
    -l, --log [PATH]                 Path to log file. Default: STDOUT
    -v, --verbose                    Verbose
        --version                    Show version
```

Use with cron to periodically get a new interesting desktop wallpaper.

Most of the time you are using a ruby switcher (rvm, rbenv, chruby, etc), which means
you will want a way to call the correct gem executable via cron. A script similar to this will
work for chruby. You would need to adapt it for your ruby switcher and ruby version.

```shell
#!/bin/bash

source /usr/local/share/chruby/chruby.sh
chruby ruby-2.2.0
FLICKPAPER=`which flickpaper`
if [ ! -z "$FLICKPAPER" ]; then
  $FLICKPAPER
fi
```

## Contributing

1. Fork it ( https://github.com/atongen/flickpaper/fork )
2. Create your feature branch (`git checkout -b my-new-feature`)
3. Commit your changes (`git commit -am 'Add some feature'`)
4. Push to the branch (`git push origin my-new-feature`)
5. Create a new Pull Request
