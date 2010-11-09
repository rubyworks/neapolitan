#require 'tilt'
require 'malt'

module Neapolitan

  # Controls rendering to a variety of back-end templating
  # and markup systems via Malt.
  #
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

    #
    #def redcloth(input)
    #  RedCloth.new(input).to_html
    #end

    #def bluecloth(input)
    #  BlueCloth.new(input).to_html
    #end

    #def rdiscount(input)
    #  RDiscount.new(input).to_html
    #end

    def rdoc(input)
      markup = RDoc::Markup::ToHtml.new
      markup.convert(input)
    end

    #def haml(input)
    #  Haml::Engine.new(input).render
    #end

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

    # Stencil Rendering
    # -----------------

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

    #
    #def erb(input, attributes)
    #  template = ERB.new(input)
    #  context  = TemplateContext.new(attributes)
    #  result   = template.result(context.__binding__)
    #  result
    #end

    #def liquid(input, attributes)
    #  template = Liquid::Template.parse(input)
    #  result   = template.render(attributes, :filters => [TemplateFilters])
    #  result
    #end

=begin
    # Require Dependencies
    # --------------------

    # TODO: Load engines only if used.

    begin ; require 'rubygems'  ; rescue LoadError ; end
    begin ; require 'erb'       ; rescue LoadError ; end
    begin ; require 'redcloth'  ; rescue LoadError ; end
    begin ; require 'bluecloth' ; rescue LoadError ; end
    begin ; require 'rdiscount' ; rescue LoadError ; end

    begin
      require 'liquid'
      #Liquid::Template.register_filter(TemplateFilters)
    rescue LoadError
    end

    begin
      require 'haml'
      #Haml::Template.options[:format] = :html5
    rescue LoadError
    end
=end

    private

    def require_rdoc
      begin
        require 'rdoc/markup'
        require 'rdoc/markup/to_html'
      rescue LoadError
      end
    end

    public

    #
    def self.render(text, format, data, &yld) 
      new.render(text, format, data, &yld)
    end

  end


=begin
  # = Clean Rendering Context
  #
  # The Factory Context is is used by ERB.

  class Context
    #include TemplateFilters

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
=end

  #
  #
  #

  #module TemplateFilters

    # NOTE: HTML truncate did not work well.

    # # HTML comment regular expression
    # REM_RE = %r{<\!--(.*?)-->}
    #
    # # HTML tag regular expression
    # TAG_RE = %r{</?\w+((\s+\w+(\s*=\s*(?:"(.|\n)*?"|'(.|\n)*?'|[^'">\s]+))?)+\s*|\s*)/?>}    #'
    #
    # #
    # def truncate_html(html, limit)
    #   return html unless limit
    #
    #   mask = html.gsub(REM_RE){ |m| "\0" * m.size }
    #   mask = mask.gsub(TAG_RE){ |m| "\0" * m.size }
    #
    #   i, x = 0, 0
    #
    #   while i < mask.size && x < limit
    #     x += 1 if mask[i] != "\0"
    #     i += 1
    #   end
    #
    #   while x > 0 && mask[x,1] == "\0"
    #     x -= 1
    #   end
    #
    #   return html[0..x]
    # end

  #end

end

