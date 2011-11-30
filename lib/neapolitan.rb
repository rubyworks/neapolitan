module Neapolitan

  if RUBY_VERSION > '1.9'
    require_relative 'neapolitan/version'
    require_relative 'neapolitan/core_ext'
    require_relative 'neapolitan/template'
    require_relative 'neapolitan/part'
    require_relative 'neapolitan/rendering'
    require_relative 'neapolitan/factory'
    require_relative 'neapolitan/cli'
  else
    require 'neapolitan/version'
    require 'neapolitan/core_ext'
    require 'neapolitan/template'
    require 'neapolitan/part'
    require 'neapolitan/factory'
    require 'neapolitan/rendering'
    require 'neapolitan/cli'
  end

  # Set default rendering system for all templates.
  # This can either be `:tilt` or `:malt`, the default.
  def self.system(libname=nil)
    @system = libname if libname
    @system
  end

  # Limit the section formats for all templates to the 
  # sepecified selection via a selection procedure.
  def self.select(&select)
    @select = select if select
    @select
  end

  # Limit the section formats for all templates via
  # a rejection procedure.
  def self.reject(&reject)
    @reject = reject if reject
    @reject
  end

  # Load template from given source.
  #
  # @param [File,IO,String] source
  #   The document to render.
  #
  # @param [Hash] options
  #   Rendering options.
  #
  def self.load(source, options={})
    Template.new(source, options)
  end

  # Specifically create a new template from a text string.
  #
  # @param [#to_s] source
  #   The document to render.
  #
  # @param [Hash] options
  #   Rendering options.
  #
  def self.text(source, options={})
    Template.new(source.to_s, options)
  end

  # Specifically create a new template from a file, given the files name.
  #
  # @example
  #   Neapolitan::Template.file('example.np')
  #
  def self.file(fname, options={})
    Template.new(File.new(fname), options)
  end

end
