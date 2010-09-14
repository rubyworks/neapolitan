Object.__send__(:remove_const, :VERSION) if Object.const_defined?(:VERSION)      # becuase Ruby 1.8~ gets in the way

module Neapolitan

  DIRECTORY = File.dirname(__FILE__)

  def self.gemfile
    @gemfile ||= (
      require 'yaml'
      YAML.load(File.new(DIRECTORY + '/gemfile'))
    )
  end

  def self.profile
    @profile ||= (
      require 'yaml'
      YAML.load(File.new(DIRECTORY + '/profile'))
    )
  end

  def self.const_missing(name)
    key = name.to_s.downcase
    gemfile[key] || profile[key] || super(name)
  end

end

