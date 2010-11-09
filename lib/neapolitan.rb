require 'neapolitan/meta/data'
require 'neapolitan/template'

module Neapolitan

  #
  def self.new(source, options={})
    Template.new(source, options)
  end

  #
  def self.file(fname, options={})
    Template.new(File.new(fname), options)
  end

end

