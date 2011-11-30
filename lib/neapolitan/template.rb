module Neapolitan

  # Template class is the main interface class.
  #
  class Template

    # Backend templating system used. Either `malt` or `tilt`.
    #
    # Note that Neapolitan is designed with Malt in mind, but Tilt
    # should work fine in most cases too. Keep in mind that Tilt
    # uses `yield` to render block content, where as Malt uses `content`.
    attr :system

    # Template text.
    attr :text

    # File name of template, if given.
    attr :file

    # Default format(s) for undecorated parts. If not otherwise set the
    # part is rendered exactly as given (which usually means `html`).
    attr :default

    # Template format(s) to apply to all sections. Typically this
    # will be a polyglot template format that injects data and performs
    # conditional rendering, such as `erb` or `liquid`. But it can
    # contain multiple formats.
    #
    # @example
    #   stencil 'erb'
    #
    attr :stencil

    # Post-formatting to be applied to all parts. These formats are applied
    # after the part specific formats. This can be useful for post-formatting
    # such as `rubypants`, a SmartyPants formatter.
    #
    attr :finish

    # Data provided in template header. Also known in some circles as
    # <i>YAML front-matter</i>.
    attr :metadata

    # @deprecated
    alias_method :header, :metadata

    # Unrendered template parts.
    attr :parts

    #
    def initialize(source, options={})
      case source
      when ::File
        @file = source.path #name
        @text = source.read
        source.close
      when ::IO
        @text = source.read
        @file = options[:file]
        source.close
      when ::String
        @text = source
        @file = options[:file]
      when Hash
        options = source
        source  = nil
        @file = options[:file]
        @text = File.read(@file)
      end

      @select   = Neapolitan.select
      @reject   = Neapolitan.reject

      @system   = options[:system] || Neapolitan.system || 'malt'

      require @system.to_s

      @default  = options[:default] || 'html'  # FIXME: 'text'
      @stencil  = options[:stencil]
      @finish   = options[:finish]

      parse
    end

    #
    def inspect
      if file
        "<#{self.class}: @file='#{file}'>"
      else
        "<#{self.class}: @text='#{text[0,10]}...'>"
      end
    end

    # Apply complex formating rules to parts.
    #
    # Here is an example of how formatting is determined
    # when no formatting block is given.
    #
    #   template.format do |part|
    #     if part.specific.empty?
    #       part.stencil + part.default + part.finish
    #     else
    #       part.stencil + part.specific + part.finish
    #     end
    #   end
    #
    def format(&block)
      @format = block if block
      @format
    end

    # TODO: filter common and default

    # Reject formats, limiting the template to only the remaining supported
    # formats.
    def reject(&block)
      @reject = block if block
      @reject
    end

    # TODO: filter common and default

    # Select formats, limit the template to only the specified formats.
    def select(&block)
      @select = block if block
      @select
    end

    # Render document.
    #
    # @return [Rendering]
    #   The encapsulation of templates completed rendering.
    #
    def render(data={}, &content)

      # TODO: is this content block buiness here needed any more?
      #if !content
      #  case data
      #  when Hash
      #    yld = data.delete('yield')
      #    content = Proc.new{ yld } if yld
      #  end
      #  content = Proc.new{''} unless content
      #end

      # apply stencil whole-clothe
      #body = apply_stencil(@body, scope, locals, &content)

      #parts = parse_parts(body)

      case data
      when Hash
        scope  = Object.new
        locals = @metadata.merge(data.rekey)
      else
        scope  = data
        locals = @metadata
      end

      rendered_parts = parts.map{ |part| render_part(part, scope, locals, &content) }

      Rendering.new(rendered_parts, @metadata)
    end

    # Save template to disk.
    #
    # @overload save(data={}, &content)
    #   Name of file is the same as the given template
    #   file less it's extension.
    #
    #   @param  [Hash] data
    #
    #   @return nothing
    #
    # @overload save(file, data={}, &content)
    #
    #   @param [String] file to save as
    #
    #   @param [Hash] data
    #
    #   @return nothing
    def save(*args, &content)
      data = Hash===args.last ? args.pop : {}
      path = args.first

      rendering = render(data, &content)

      path = path || rendering.metadata['output']
      path = path || path.chomp(File.extname(file))

      path = Dir.pwd unless path
      if File.directory?(path)
        file = File.join(path, file.chomp(File.extname(file)) + extension)
      else
        file = path
      end

      if $DRYRUN
        $stderr << "[DRYRUN] write #{fname}"
      else
        File.open(file, 'w'){ |f| f << rendering.to_s }
      end
    end

   private

    # TODO: Should a stencil be applied once to the entire document?
    # While it would be nice, b/c it would speed things up a bit, it
    # could present an issue with the `---` dividers and would be useless
    # for certain formats like Haml. So probably not.

    # Apply stencil whole-clothe.
    #def apply_stencil(body, scope, locals, &content)
    #  return body unless stencil
    #  factory.render(body, stencil, scope, locals, &content)
    #end

    # Parse template document into metadata and parts.
    def parse
      parts = text.split(/^\-\-\-/)

      if parts.size == 1
        data = {}
        #@parts << Part.new(sect[0]) #, *[@stencil, @default].compact.flatten)
      else
        parts.shift if parts.first.strip.empty?
        data = YAML::load(parts.first)
        if Hash === data
          parts.shift
        else
          data = {}
        end
      end

      parse_metadata(data)

      @parts = parts.map{ |part| Part.parse(self, part) }
    end

    #
    def parse_metadata(data)
      @default  = data.delete('default') if data.key?('default')
      @stencil  = data.delete('stencil') if data.key?('stencil')
      @finish   = data.delete('finish')  if data.key?('finish')
      @metadata = data
    end

    # Render a part.
    def render_part(part, scope, locals={}, &content)
      formats = part.formatting(&@format)

      formats = formats.flatten.compact.uniq

      formats.reject!(&@reject) if @reject
      formats.select!(&@select) if @select

      formats.inject(part.text) do |text, format|
        factory.render(text, format, scope, locals, &content)
      end
    end

    # Get cached {Factory} instance.
    def factory
      @factory ||= Factory.new(:tilt=>@tilt)
    end

  end

end
