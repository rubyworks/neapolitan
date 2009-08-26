require 'brite/page'

module Brite

  # Post class
  class Post < Page

    def default_layout
      site.defaults.postlayout
    end

    #def to_contextual_attributes
    #  { 'site' => site.to_h, 'post' => to_h }
    #end

=begin
    #
    def render(content=nil)
      attributes = to_contextual_attributes
      #attributes['page']['content'] = content if content

      output = parts.map{ |part| part.render(stencil, attributes) }.join("\n")

      # content
      @content = output

      if layout
        output = site.lookup_layout(layout).render(output)
      end
      output
    end
=end

  end

end

