module Neapolitan

  def self.package
    @package ||= (
      require 'yaml'
      YAML.load(File.new(File.dirname(__FILE__) + '/package'))
    )
  end

  def self.profile
    @profile ||= (
      require 'yaml'
      YAML.load(File.new(File.dirname(__FILE__) + '/profile'))
    )
  end

  def self.const_missing(name)
    key = name.to_s.downcase
    package[key] || profile[key] || super(name)
  end

end

# Becuase Ruby 1.8~ gets in the way
Object.__send__(:remove_const, :VERSION) if Object.const_defined?(:VERSION)

