require 'neapolitan/factory'
require 'neapolitan/part'

module Neapolitan

  #
  class Template

    # Template text.
    attr :text

    # File name of template, if given.
    attr :file

    # Header data, also known as <i>front matter</i>.
    attr :header

    # Templating format to apply "whole-clothe".
    attr :stencil

    # Default format(s) for undecorated parts.
    # If not otherwise set the default is 'html'.
    attr :default

    # Common format(s) to be applied to all parts.
    # These are applied at the end.
    attr :common

    # Rendering formats to disallow.
    attr :reject

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

      @types   = options[:types]

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

    # Rejection procedure.
    def reject(&block)
      @reject = block if block
      @reject
    end

    # Unrendered template parts.
    def parts
      @parts
    end

    #
    def render(data={}, &block)
      Rendering.new(self, data, &block)
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

  private

    # TODO: Should a stencil be applied once to the entire document?
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

  end

  # Template Rendering
  class Rendering

    #
    attr :template

    # Source of data, can either be an
    # Hash, Binding or Object.
    attr :data

    #
    attr :block

    #
    def initialize(template, data, &block)
      @template = template
      @data     = data
      @block    = block

      if !block
        case data
        when Hash
          yld = data.delete('yield')
          @block = Proc.new{ yld } if yld
        end
        @block = Proc.new{''} unless @block
      end

      render
    end

    def to_s
      #render unless @output
      @output
    end

    # Renderings of each part.
    def to_a
      #render unless @output
      @renders
    end

    # Summary is the rendering of the first part.
    def summary
      #render unless @output
      @summary
    end

    #
    def header
      @template.header
    end

  private

    def render
      @renders = @template.parts.map{ |part| render_part(part, @data, &@block) }
      @summary = @renders.first
      @output  = @renders.join("\n")
    end

    #
    def render_part(part, data, &block)
      formats = part.formats
      formats = template.default if formats.empty?
      formats = [formats, template.common].flatten.compact

      case template.reject
      when Array
        formats = formats - template.reject
      when Proc
        formats = formats.reject(&template.reject)
      end

      formats = [template.stencil, *formats].compact

      formats.inject(part.text) do |text, format|
        factory.render(text, format, data, &block)
      end
    end

    #
    def factory
      @factory ||= Factory.new
    end

  end

end
