require 'neapolitan/meta/data'
#require 'tilt'
require 'malt'

module Neapolitan

  # Access project metadata.
  def self.metadata
    @metadata ||= (
      require 'yaml'
      YAML.load(File.new(File.dirname(__FILE__) + '/neapolitan.yml'))
    )
  end

  # Access project metadata as constants.
  def self.const_missing(name)
    key = name.to_s.downcase
    metadata[key] || super(name)
  end

  #
  def self.load(source, options={})
    Template.new(source, options)
  end

  #
  def self.text(source, options={})
    Template.new(source.to_s, options)
  end

  #
  def self.file(fname, options={})
    Template.new(File.new(fname), options)
  end

  #
  class Template

    # Template text.
    attr :text

    # File name of template, if given.
    attr :file

    # Templating format to apply "whole-clothe".
    attr :stencil

    # Default format(s) for undecorated parts.
    # If not otherwise set the default is 'html'.
    attr :default

    # Common format(s) to be applied to all parts.
    # These are applied at the end.
    attr :common

    # Rendering formats to disallow.
    #attr :reject

    # Header data, also known as <i>front matter</i>.
    attr :header

    #
    def initialize(source, options={})
      case source
      when ::File
        @file = source.path #name
        @text = source.read
        source.close
      when ::IO
        @text = source.read
        @file = options[:file]
        source.close
      when ::String
        @text = source
        @file = options[:file]
      when Hash
        options = source
        source  = nil
        @file = options[:file]
        @text = File.read(@file)
      end

      @stencil = options[:stencil]
      @default = options[:default] || 'html'
      @common  = options[:common]
      #@reject  = options[:reject]

      parse
    end

    #
    def inspect
      if file
        "<#{self.class}: @file='#{file}'>"
      else
        "<#{self.class}: @text='#{text[0,10]}'>"
      end
    end

    # Rejection formats.
    #--
    # TODO: filter common and default
    #++
    def reject(&block)
      parts.each do |part|
        part.formats.reject!(&block)
      end
    end

    # Select formats.
    #--
    # TODO: filter common and default
    #++
    def select(&block)
      parts.each do |part|
        part.formats.select!(&block)
      end
    end

    # Unrendered template parts.
    def parts
      @parts
    end

    #
    def render(data={}, &block)
      if !block
        case data
        when Hash
          yld = data.delete('yield')
          block = Proc.new{ yld } if yld
        end
        block = Proc.new{''} unless block
      end

      renders = parts.map{ |part| render_part(part, data, &block) }

      Rendering.new(renders, header)
    end

    # :call-seq:
    #   save(data={}, &block)
    #   save(file, data={}, &block)
    #
    def save(*args, &block)
      data = Hash===args.last ? args.pop : {}
      path = args.first

      rendering = render(data, &block)

      path = path || rendering.header['output']
      path = path || path.chomp(File.extname(file))

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

  private

    #--
    # TODO: Should a stencil be applied once to the entire document?
    #++
    def parse
      @parts = []

      sect = text.split(/^\-\-\-/)

      if sect.size == 1
        @header = {}
        @parts << Part.new(sect[0]) #, *[@stencil, @default].compact.flatten)
      else
        sect.shift if sect.first.strip.empty?

        head = sect.shift
        head = YAML::load(head)
        parse_header(head)

        sect.each do |body|
          index   = body.index("\n")
          formats = body[0...index].strip
          formats = formats.split(/\s+/) if String===formats
          #formats = @default if formats.empty?
          #formats.unshift(@stencil) if @stencil
          text    = body[index+1..-1]
          @parts << Part.new(text, *formats)
        end
      end
    end

    #
    def parse_header(head)
      @header  = head
      @default = head.delete('default'){ @default }
      @common  = head.delete('common'){ @common }
    end

    #
    def render_part(part, data, &block)
      formats = part.formats
      formats = default if formats.empty?
      formats = [formats, common].flatten.compact

      #case reject
      #when Array
      #  formats = formats - reject.map{|r|r.to_s}
      #when Proc
      #  formats = formats.reject(&reject)
      #end

      formats = [stencil, *formats].compact

      formats.inject(part.text) do |text, format|
        factory.render(text, format, data, &block)
      end
    end

    #
    def factory
      @factory ||= Factory.new
    end

  end

  # A part is a section of a template. Templates can be segmented into
  # parts using the '--- FORMAT' notation.
  class Part
    # Rendering formats (html, rdoc, markdown, textile, etc.)
    attr :formats

    # Body of text as given in the part.
    attr :text

    #
    def initialize(text, *formats)
      @text     = text
      @formats  = formats
    end
  end

  # Template Rendering
  class Rendering
    #
    def initialize(renders, header)
      @renders = renders
      @summary = renders.first
      @output  = renders.join("\n")
      @header  = header
    end

    #
    def to_s
      @output
    end

    # Renderings of each part.
    def to_a
      @renders
    end

    # Summary is the rendering of the first part.
    def summary
      @summary
    end

    #
    def header
      @header
    end
  end

  # Controls rendering to a variety of back-end templating
  # and markup systems via Malt.
  class Factory
    #
    attr :types

    #
    def initialize(options={})
      @types = options[:types]
    end

    #
    def render(text, format, data, &yld) 
      case format
      when /^coderay/
        coderay(text, format)
      when /^syntax/
        syntax(text, format)
      else
        render_via_malt(text, format, data, &yld)
      end
    end

    #
    def render_via_malt(text, format, data, &yld)
      doc = malt.text(text, :type=>format.to_sym)
      doc.render(data, &yld)
    end

    #
    def render_via_tilt(text, format, data, &yld)
      if engine = Tilt[format]
        case data
        when Hash
          scope = Object.new
          table = data
        when Binding
          scope = data.eval('self')
          table = {}
        else # object scope
          scope = data
          table = {}
        end
        engine.new{text}.render(scope, table, &yld)
      else
        text
      end
    end

    #
    def malt
      @malt ||= (
        if types && !types.empty?
          Malt::Machine.new(:types=>types)
        else
          Malt::Machine.new
        end
      )
    end

    def coderay(input, format)
      require 'coderay'
      format = format.split('.')[1] || :ruby #:plaintext
      tokens = CodeRay.scan(input, format.to_sym) #:ruby
      tokens.div()
    end

    #
    def syntax(input, format)
      require 'syntax/convertors/html'
      format = format.split('.')[1] || 'ruby' #:plaintext
      lines  = true
      conv   = Syntax::Convertors::HTML.for_syntax(format)
      conv.convert(input,lines)
    end

    #
    #def render_stencil(stencil, text, attributes)
    #  case stencil
    #  when 'rhtml'
    #    erb(text, attributes)
    #  when 'liquid'
    #    liquid(text, attributes)
    #  else
    #    text
    #  end
    #end

    public

    #
    def self.render(text, format, data, &yld) 
      new.render(text, format, data, &yld)
    end

  end

  # Command line interface.
  def self.cli(*argv)
    options = {}

    option_parser(options).parse!(argv)

    if src = options[:source]
      data = YAML.load(File.new(src))
    else
      data = {} #@source ||= YAML.load(STDIN.read)
    end

    files = argv

    begin
      files.each do |file|
        template = Template.new(File.new(file))
        if options[:output]
          #template.save(data)
        else
          puts template.render(data)
        end
      end
    rescue => e
      $DEBUG ? raise(e) : puts(e.message)
    end
  end

  #--
  # TODO: Save to output.
  #++
  def self.option_parser(options)
    require 'optparse'

    OptionParser.new do |opt|
      opt.banner = "neapolitan [file1 file2 ...]"
      #opt.on("--output", "-o [PATH]", "save output to specified directory") do |path|
      #  options[:output] = path
      #end
      opt.on("--source", "-s [FILE]", "data souce (YAML file)") do |file|
        options[:source] = file
      end
      opt.on("--trace", "show extra operational information") do
        $TRACE = true
      end
      opt.on("--dryrun", "-n", "don't actually write to disk") do
        $DRYRUN = true
      end
      opt.on("--debug", "run in debug mode") do
        $DEBUG   = true
        $VERBOSE = true
      end
      opt.on_tail("--help", "display this help message") do
        puts opt
        exit
      end
    end

  end

end
