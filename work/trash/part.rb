module Neapolitan

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

end

