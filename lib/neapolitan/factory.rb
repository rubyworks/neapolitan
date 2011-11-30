module Neapolitan

  # Controls rendering to a variety of back-end templating
  # and markup systems via Malt.
  #
  class Factory
    #
    attr :types

    # @param [Hash] options
    #
    # @option options [Array] :types
    #
    def initialize(options={})
      @types  = options[:types]
      @system = options[:system] || :malt
    end

    #
    def render(text, format, scope, locals, &content) 
      case format
      when /^coderay/
        coderay(text, format)
      when /^syntax/
        syntax(text, format)
      when /^rubypants/
        rubypants(text, format)
      else
        if @system == :tilt
          render_via_tilt(text, format, scope, locals, &content)
        else
          render_via_malt(text, format, scope, locals, &content)
        end
      end
    end

    # Render via Malt.
    def render_via_malt(text, format, scope, locals, &content)
      doc = malt.text(text, :type=>format.to_sym)
      doc.render(scope, locals, &content)
    end

    # Render via Tilt.
    def render_via_tilt(text, format, scope, locals, &content)
      if engine = Tilt[format]
        #case data
        #when Hash
        #  scope = Object.new
        #  table = data
        #when Binding
        #  scope = data.eval('self')
        #  table = {}
        #else # object scope
        #  scope = data
        #  table = {}
        #end
        engine.new{text}.render(scope, locals, &content)
      else
        text
      end
    end

    # Get cached instance of Malt controller.
    #
    # @return [Malt::Machine] mutli-format renderer
    def malt
      @malt ||= (
        if types && !types.empty?
          Malt::Machine.new(:types=>types)
        else
          Malt::Machine.new
        end
      )
    end

    # Apply `coderay` syntax highlighting. This is a psuedo-format.
    def coderay(input, format)
      require 'coderay'
      format = format.split('.')[1] || :ruby #:plaintext
      tokens = CodeRay.scan(input, format.to_sym) #:ruby
      tokens.div()
    end

    # Apply `syntax` syntax highlighting. This is a psuedo-format.
    def syntax(input, format)
      require 'syntax/convertors/html'
      format = format.split('.')[1] || 'ruby' #:plaintext
      lines  = true
      conv   = Syntax::Convertors::HTML.for_syntax(format)
      conv.convert(input,lines)
    end

    #
    def rubypants(input_html, format)
      require 'rubypants'
      format, flag = format.split('.')
      flag  = (flag || 2).to_i
      pants = RubyPants.new(input_html, flag)
      pantts.to_html
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
    def self.render(text, format, data, &content) 
      new.render(text, format, data, &content)
    end

  end

end
