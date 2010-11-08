require 'neapolitan/meta/data'
require 'neapolitan/template'

module Neapolitan

  #
  def self.file(fname, options={})
    Template.new(File.new(fname), options)
  end

end

