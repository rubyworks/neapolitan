require 'chocolates/factory'

module Chocolates

  # A Part is the section of a page. Pages can be segmented into
  # parts using the '--- FORMAT' notation.
  class Part

    # Markup format (html, rdoc, markdown, textile)
    attr :formats

    # Body of text as given in the part.
    attr :text

    #
    def initialize(text, *formats)
      @text    = text
      @formats = formats
    end

    #
    def render(source, &block)
      formats.inject(text) do |rendering, format|
        factory.render(format, rendering, source, &block)
      end
    end

    #
    def factory
      Factory
    end

  end

end

