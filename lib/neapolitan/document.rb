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

    # :call-seq:
    #   save(data={}, &block)
    #   save(file, data={}, &block)
    #
    def save(*args, &block)
      data = Hash===args.last ? args.pop : {}
      path = args.first

      rendering = render(data, &block)

      path = path || rendering.header['file']

      path = path || file.chomp(File.extname(file))

      path = Dir.pwd unless path
      if File.directory?(path)
        file = File.join(path, file.chomp(File.extname(file)) + extension)
      else
        file = path
      end

      if $DRYRUN
        $stderr << "[DRYRUN] write #{fname}"
      else
        File.open(file, 'w'){ |f| f << rendering.to_s }
      end
    end

  end

end
