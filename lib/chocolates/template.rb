require 'chocolates/part'

module Chocolates

  #
  class Template

    # Template text.
    attr :text

    # Source of data, can either be an
    # Hash, Binding or Object.
    attr :data

    # Front matter.
    attr :matter

    # Master templating format.
    attr :stencil

    # Default markup type (html).
    attr :markup

    ## Output extension (defualt is 'html')
    #attr :extension

    # Provide template +text+, +data+ and yield +block+.
    def initialize(text, data={}, &block)
      @text    = text
      @data    = data
      @block   = block

      if !@block
        yld = data.delete('yield')
        @block = Proc.new{ yld } if yld
      end

      @parts   = []
      @renders = []
      @output  = nil

      # defaults
      @markup  = 'html'
      @stencil = nil

      parse
    end

    #
    def inspect
      "<#{self.class}: @text='#{text[0,10]}'>"
    end

    #def to_contextual_attributes
    #  { 'site'=>site.to_h, 'page'=>to_h, 'root'=>root, 'work'=>work }
    #end

    ##
    #def to_liquid
    #  to_contextual_attributes
    #end

    def to_s
      render unless @output
      @output
    end

    # Renderings of each part.
    def to_a
      render unless @output
      @renders
    end

    # Summary is the rendering of the first part.
    def summary
      render unless @output
      @summary
    end

  private

    #
    def render
      @renders = @parts.map{ |part| part.render(@data, &@block) }
      @summary = @renders.first
      @output  = @renders.join("\n")
    end

    #
    def parse
      @renders = nil
      @summary = nil

      hold = []
      #text = File.read(file)
      sect = text.split(/^\-\-\-/)

      if sect.size == 1
        @matter = {}
        @parts << Part.new(sect[0], *[@markup, @stencil].compact)
      else
        #void = sect.shift
        head = sect.shift
        head = YAML::load(head)
        header(head)

        sect.each do |body|
          index   = body.index("\n")
          format  = body[0...index].strip
          format  = site.defaults.format if format.empty?
          formats = format.split(/\s+/)
          text    = body[index+1..-1]     
          @parts << Part.new(text, *formats)
        end
      end
    end

    #
    def header(head)
      @matter    = head
      @stencil   = head.delete('stencil'){ @stencil }
      @markup    = head.delete('markup'){ @markup }
      #@extension = head.delete('extension'){ @extension }
    end

    # Unrendered template parts.
    def parts
      @parts
    end

  end

end

