# Flickpaper

A [Flickr App](https://www.flickr.com/services/apps/72157658406991003) that sets your GNOME wallpaper to a recent interesting photo

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
    -v, --verbose                    Verbose
        --version                    Show version
```

Use with cron to periodically get a new interesting desktop wallpaper.

## Contributing

1. Fork it ( https://github.com/atongen/flickpaper/fork )
2. Create your feature branch (`git checkout -b my-new-feature`)
3. Commit your changes (`git commit -am 'Add some feature'`)
4. Push to the branch (`git push origin my-new-feature`)
5. Create a new Pull Request
