require 'chocolates/part'

module Chocolates

  #
  class Template

    # Template text.
    attr :text

    # Header data, also known as <i>front matter</i>.
    attr :header

    # Templating format to apply "whole-clothe".
    attr :stencil

    # Default format(s) for undecorated parts.
    # If not set defaults to 'html'.
    attr :default

    ## Output extension (defualt is 'html')
    #attr :extension

    # Provide template +text+, +data+ and yield +block+.
    def initialize(text, options={})
      @text    = text
      @stencil = options[:stencil]
      @default = [options[:default] || 'html'].flatten
      @parts   = []
      parse
    end

    #
    def inspect
      "<#{self.class}: @text='#{text[0,10]}'>"
    end

    # Unrendered template parts.
    def parts
      @parts
    end

    #
    def render(data={}, &block)
      Rendering.new(self, data, &block)
    end

  private

    #
    def parse
      sect = text.split(/^\-\-\-/)

      if sect.size == 1
        @header = {}
        @parts << Part.new(sect[0], *[@stencil, @default].compact.flatten)
      else
        sect.shift if sect.first.strip.empty?
        #void = sect.shift if sect.first.strip.empty?
        head = sect.shift
        head = YAML::load(head)
        parse_header(head)

        sect.each do |body|
          index   = body.index("\n")
          formats = body[0...index].strip
          formats = formats.split(/\s+/) if String===formats
          formats = @default if formats.empty?
          formats << @stencil if @stencil
          text    = body[index+1..-1]
          @parts << Part.new(text, *formats)
        end
      end
    end

    #
    def parse_header(head)
      @header  = head
      @stencil = head.delete('stencil'){ @stencil }
      @default = head.delete('default'){ @default }
      #@extension = head.delete('extension'){ @extension }
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

      if !@block
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
      @renders = @template.parts.map{ |part| part.render(@data, &@block) }
      @summary = @renders.first
      @output  = @renders.join("\n")
    end

  end

end

