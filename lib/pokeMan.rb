require "pokeman/version"
require 'pokeman/pokeutil'

module PokeMan

  class Configuration
    attr_accessor :home, :pwd, :gem_path, :host, :user
  end

  class << self
    attr_accessor :configuration
    def configure
      self.configuration ||= Configuration.new
      yield(configuration)
    end
  end

  def self.root
    File.dirname __dir__
  end

  def self.bin
    File.join root, 'bin'
  end

  def self.lib
    File.join root, 'lib'
  end

  def self.files
    File.join root, 'lib/files'
  end

  def self.tools
    File.join root, 'lib/tools'
  end

  def self.commands
    File.join root, 'lib/commands'
  end

  PokeMan.configure do |config|
    config.gem_path = ENV['GEM_PATH']
    config.host = ENV['HOST']
    config.user = ENV['USER']
    config.home = ENV['HOME']
    config.pwd = ENV['PWD']
  end

end
