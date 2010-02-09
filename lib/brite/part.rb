module Brite

  # A Part is the section of a page. Pages can be segmented into
  # parts using the '--- FORMAT' notation.
  class Part

    # Markup format (html, rdoc, markdown, textile)
    attr :format

    # Body of text as given in the part.
    attr :text

    #
    def initialize(text, format=nil)
      @format = format
      @text   = text
    end

    #
    def render(type, attributes, &output)
      template_engine.render(type, format, text, attributes, &output)
    end

    #
    def template_engine
      TemplateEngine
    end

  end

end

