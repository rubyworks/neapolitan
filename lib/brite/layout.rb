module Brite

  # Layout class
  class Layout < Page
    undef_method :save

    #def to_contextual_attributes
    #  { 'site'=>site.to_h }
    #end

    #
    def render(attributes={})
      #attributes = to_contextual_attributes
      #attributes['content'] = content if content

      output = parts.map{ |part| part.render(stencil, attributes) }.join("\n")

      #@content = output

      attributes = attributes.merge('content'=>output)

      if layout
        output = site.lookup_layout(layout).render(attributes)
      end

      output
    end

    # Layouts have no default layout.
    def default_layout
      nil
    end

  end

end
