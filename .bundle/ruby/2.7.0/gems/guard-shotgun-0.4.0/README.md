# Guard::Shotgun

Guard::Shotgun automatically starts and restarts Rack applications (through `rackup`) when needed. As useful as Shotgun when developing a Rack app.

Tested on:

* Ruby 1.9.2-p290
* Ruby 2.0.0-p247

## Why?

* You are **developing with Rack** and you have to **restart your development server each time you change your source code**?
* You are **using Shotgun** to do this, but well, the **latest version is not showing the logs anymore** in your console, which makes developing a little harder?
* Reloading your whole Rack app with each request seems a bit overkill? Seems better to only reload it on a file change?

If you have answered 'yes' to any of these questions, you may find some use to this plugin.

## Install

Please be sure to have [Guard](http://github.com/guard/guard) installed before continuing.

Install the gem:

    gem install guard-shotgun

Or add it to your Gemfile (inside development group):

    gem 'guard-shotgun', :git => 'https://github.com/rchampourlier/guard-shotgun.git'

Add guard definition to your Guardfile by running this command:

    guard init shotgun

## Usage

This guard plugin is intended to be used when **developing a Rack application**, loaded through `rackup`.

**It allows automatic reloading of your Rack server when a file is changed.**

> It provides the same service as the **Shotgun** gem, relying on **Guard** to watch for your files.

Please read [Guard usage doc](http://github.com/guard/guard#readme)

## Guardfile

For example, to look at the `main.rb` file in your application directory, just set this guard:

    guard 'shotgun' do
      watch('main.rb')
    end

**Common config**

Here we watch Ruby files within the `app` and `lib` directories, as well as the `config.ru` file. We also use Thin as a server instead of the default WEBRick.

    guard 'shotgun', :server => 'thin' do
      watch %r{^(app|lib)/.*\.rb}
      watch 'config.ru'
    end

Please read [Guard doc](http://github.com/guard/guard#readme) for more info about Guardfile DSL.


## Options

* `server`: the name of the server to use. The option is passed to the `rackup` command. You may use for example `WEBrick` (default), `thin`...
* `port`: the port on which to run the server, the option is also passed to the `rackup` command.


## Testing

There is currently no spec :S. I intend to write some (won't need much). You may however go to the `spec/dummy_app`  directory and run:

```
bundle install
bundle exec guard
```

This way, you can check it's working correctly. You can play with the `spec/dummy_app/app/base_app.rb` file and introduce some bug so that you may see a failing start is correctly handled too.


## Compatibility with Guard

* 0.2.0 is compatible (and dependent on) Guard ~> 1.0

## History

#### 0.4.0

* Merged PR with the changes to make it compatible with Guard 2. Thanks to
@jnv!

#### 0.3.1

* Merged PR fixing issue with Spoon

#### 0.3.0

* Adding dependency on Guard ~> 1.0
* Fixed an issue when autoloading the Notifier class
* Minor changes to README, repo and dummy_app

#### 0.2.0

* Merged an update by Colin Rymer

#### 0.1.0

* Essentially repository cleanup and README update.

#### 0.0.6

* Improved start/stop management:
  * Exiting Guard will trigger INT signal instead of TERM, stopping WEBRick gently.
  * Failure to start will be detected too after a 10 seconds timeout, and the app will just get reloaded when you change a file.

#### 0.0.4

Killing Rack when reloading on change without waiting for requests to be completed.

#### 0.0.3

Initial release

## TODOs

* Add some options: host, port...
* Allow starting Rack applications without using rackup.
* Tests.

Help is welcome!


## Development

* Source hosted at [GitHub](http://github.com/crymer11/guard-shotgun)
* Report issues/Questions/Feature requests on [GitHub Issues](http://github.com/crymer11/guard-shotgun/issues)

Pull requests are very welcome! Make sure your patches are well tested. Please create a topic branch for every separate change
you make.

## Authors

[Romain Champourlier](http://github.com/rchampourlier)
[Colin Rymer](http://github.com/crymer11)


## Credits

This gem has been built from [guard-webrick](https://github.com/guard/guard-webrick) of [Fletcher Nichol](http://github.com/fnichol).
