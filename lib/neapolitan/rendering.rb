module Neapolitan

  # Encapsulates a template rendering.
  #
  class Rendering

    #
    def initialize(renders, metadata)
      @renders  = renders
      @summary  = renders.first
      @output   = renders.join("\n")
      @metadata = metadata
    end

    #
    def to_s
      @output
    end

    # Renderings of each part.
    def to_a
      @renders
    end

    # Summary is the rendering of the first part.
    def summary
      @summary
    end

    #
    def metadata
      @metadata
    end

    # for temporary backward comptability
    alias_method :header, :metadata
  end

end
