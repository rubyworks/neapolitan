require 'neapolitan/template'

module Neapolitan

  # = Neapolitan Document
  #
  # The Document class encapsulates a file which
  # can be then be rendered via a Neapolitan::Template.
  class Document

    # File path.
    attr :file

    #
    attr :template

    # New Document object.
    #
    # file    - path to neapolitan formatted file
    # options - configuration passed on to the Template class
    #
    # Returns a new Document object.
    def initialize(file, options={})
      case file
      when File
        @file = file.name
        @text = file.read
        @file.close 
      when String
        @file = file
        @text = File.read(file)
      end

      @template = Template.new(@text, options)
    end

    #
    def inspect
      "<#{self.class}: @file='#{file}'>"
    end

    # Name of file less extname.
    #def name
    #  @name ||= file.chomp(File.extname(file))
    #end

    #
    def render(data={}, &block)
      @template.render(data, &block)
    end

    # TODO: how to handle extension?
    def save(*path_and_data, &block)
      data = Hash===path_and_data.last ? path_and_data.pop : {}
      path = path_and_data

      rendering = render(data, &block)
      extension = rendering.header['extension'] || '.html'

      path = Dir.pwd unless path
      if File.directory?(path)
        file = File.join(path, file.chomp(File.extname(file)) + extension)
      else
        file = path
      end

      if $DRYRUN
        $stderr << "[DRYRUN] write #{fname}"
      else
        File.open(fname, 'w'){ |f| f << rendering.to_s }
      end
    end

  end

end
