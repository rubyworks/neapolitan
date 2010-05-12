require 'chocolates/template'

module Chocolates

  # = Document
  #
  class Document

    # File path.
    attr :file

    def initialize(file, data={}, &block)
      case file
      when File
        @file = file.name
        @text = file.read
        @file.close 
      when String
        @file = file
        @text = File.read(file)
      end

      @template = Template.new(@text, data, &block)
    end

    #
    def inspect
      "<#{self.class}: @file='#{file}'>"
    end

    #
    def name
      @name ||= file.chomp(File.extname(file))
    end

=begin

    ##
    #def url
    #  @url ||= '/' + name + extension
    #end

    ## DEPRECATE: Get rid of this and use rack to test page instead of files.
    #def root
    #  '../' * file.count('/')
    #end

    ##
    #def work
    #  '/' + File.dirname(file)
    #end
=end

    #
    def save(path=nil)
      raise "template has not been rendered" unless output
      path = Dir.pwd unless path
      if File.directory?(path)
        file = File.join(path, file.chomp(File.extname(file)) + extension)
      else
        file = path
      end
      if Choclates.dryrun?
        $stderr << "[DRYRUN] write #{fname}"
      else
        File.open(fname, 'w'){ |f| f << output }
      end
    end

    #
    def to_s
      @template.to_s
    end

    #
    def summary
      @template.summary
    end

  end

end

