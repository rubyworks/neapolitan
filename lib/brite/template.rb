module Brite

  # Stencil controls rendering to a variety
  # of back-end templating and markup systems.
  #
  module TemplateEngine
    extend self

    #
    def render(stencil, format, text, attributes)
      text = render_format(format, text)
      text = render_stencil(stencil, text, attributes)
      text
    end

    #
    def render_format(format, text)
      case format
      when 'rdoc'
        rdoc(text)
      when 'markdown'
        rdiscount(text)
      when 'textile'
        redcloth(text)
      when /^coderay/
        coderay(text, format)
      else # html
        text
      end
    end

    #
    def render_stencil(stencil, text, attributes)
      case stencil
      when 'rhtml'
        erb(text, attributes)
      when 'liquid'
        liquid(text, attributes)
      else
        text
      end
    end

    # Format Renderers
    # ----------------

    #
    def redcloth(input)
      RedCloth.new(input).to_html
    end

    def bluecloth(input)
      BlueCloth.new(input).to_html
    end

    def rdiscount(input)
      RDiscount.new(input).to_html
    end

    def rdoc(input)
      markup = SM::SimpleMarkup.new
      format = SM::ToHtml.new
      markup.convert(input, format)
    end

    def coderay(input, format)
      require 'coderay'
      format = format.split('.')[1] || :ruby #:plaintext
      tokens = CodeRay.scan(input, format.to_sym) #:ruby
      tokens.div()
    end

    # Stencil Renderers
    #------------------

    #
    def erb(input, attributes)
      template = ERB.new(input)
      context  = Context.new(attributes)
      result   = template.result(context.__binding__)
      result
    end

    def liquid(input, attributes)
      template = Liquid::Template.parse(input)
      result   = template.render(attributes) #'products' => Product.find(:all) )
      result
    end

    # TODO Load these only if used.

    begin ; require 'rubygems'  ; rescue LoadError ; end
    begin ; require 'erb'       ; rescue LoadError ; end
    begin ; require 'redcloth'  ; rescue LoadError ; end
    begin ; require 'bluecloth' ; rescue LoadError ; end
    begin ; require 'rdiscount' ; rescue LoadError ; end
    begin ; require 'liquid'    ; rescue LoadError ; end

    begin
      require 'rdoc/markup/simple_markup'
      require 'rdoc/markup/simple_markup/to_html'
    rescue LoadError
    end

  end

  # Render Context
  class Context
    instance_methods(true).each{ |m| private m unless m =~ /^__/ }

    def initialize(attributes={})
      @attributes = attributes
    end

    def __binding__
      binding
    end

    def to_h
      @attributes
    end

    def method_missing(s, *a)
      s = s.to_s
      @attributes.key?(s) ? @attributes[s] : super
    end
  end

end

