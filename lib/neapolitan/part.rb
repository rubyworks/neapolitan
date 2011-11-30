module Neapolitan

  # A part is a section of a template. Templates can be segmented into
  # parts using the '--- FORMAT' notation.
  class Part

    # Parse text body and create new part.
    def self.parse(template, body)
      index   = body.index("\n")
      format  = body[0...index].strip
      text    = body[index+1..-1].strip

      new(template, text, format)
    end

    # The template to which the part belongs.
    attr :template

    # Body of text as given in the part.
    attr :text

    # Setup new Part instance.
    #
    # @param [String] text 
    #   The parts body.
    #
    # @param [Array] formats
    #   The template formats to apply to the body text.
    #
    def initialize(template, text, format)
      @template = template
      @text     = text
      @format   = format
    end

    # Rendering format as given in the template document.
    def format
      @format
    end

    # Part specific format split into array.
    def specific
     @_specific ||= split_format(format)
    end

    # Template default format split into array.
    def default
      @_default ||= split_format(template.default)
    end

    # Template default format split into array.
    def stencil
      @_stencil ||= split_format(template.stencil)
    end

    # Template default format split into array.
    def finish
      @_finish ||= split_format(template.finish)
    end

    #
    def formatting(&custom)
      if custom
        custom.call(self)
      else
        if specific.empty?
          stencil + default + finish
        else
          stencil + specific + finish
        end
      end
    end

   private

    #
    def split_format(format)
      case format
      when nil
        []
      when Array
        format
      else
        format.to_str.split(/\s+/)
      end
    end
  end

end
