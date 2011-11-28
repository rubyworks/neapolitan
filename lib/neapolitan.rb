module Neapolitan

  if RUBY_VERSION > '1.9'
    require_relative 'neapolitan/version'
    require_relative 'neapolitan/core_ext'
    require_relative 'neapolitan/cli'
  else
    require 'neapolitan/version'
    require 'neapolitan/core_ext'
    require 'neapolitan/cli'
  end

  # Set default rendering system for all templates.
  # This can either be `:tilt` or `:malt`, the default.
  def self.system(libname=nil)
    @system = libname if libname
    @system
  end

  # Limit the section formats for all templates to the 
  # sepecified selection via a selection procedure.
  def self.select(&select)
    @select = select if select
    @select
  end

  # Limit the section formats for all templates via
  # a rejection procedure.
  def self.reject(&reject)
    @reject = reject if reject
    @reject
  end

  # Load template from given source.
  #
  # @param [File,IO,String] source
  #   The document to render.
  #
  # @param [Hash] options
  #   Rendering options.
  #
  def self.load(source, options={})
    Template.new(source, options)
  end

  # Specifically create a new template from a text string.
  #
  # @param [#to_s] source
  #   The document to render.
  #
  # @param [Hash] options
  #   Rendering options.
  #
  def self.text(source, options={})
    Template.new(source.to_s, options)
  end

  # Specifically create a new template from a file, given the files name.
  #
  # @example
  #   Neapolitan::Template.file('example.np')
  #
  def self.file(fname, options={})
    Template.new(File.new(fname), options)
  end

  # Template class is the main interface class.
  #
  class Template

    # Template text.
    attr :text

    # File name of template, if given.
    attr :file

    # Default format(s) for undecorated parts.
    # If not otherwise set the default is 'html'.
    attr :default

    # Templating format to apply "whole-clothe".
    attr :stencil

    # Common formatting to be applied to all parts.
    # These are applied at the end.
    attr :common

    # Header data, also known as <i>front matter</i>.
    attr :header

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

      head, @body = split_text

      data = load_header(head)

      @default  = data.delete('default') || options[:default] || 'html'
      @common   = data.delete('common')  || options[:common]
      @stencil  = data.delete('stencil') || options[:stencil]

      @metadata = data.rekey

      require @system.to_s

      #parse
    end

    #
    def inspect
      if file
        "<#{self.class}: @file='#{file}'>"
      else
        "<#{self.class}: @text='#{text[0,10]}...'>"
      end
    end

    # TODO: filter common and default

    # Reject formats, limiting the template to only the remaining supported
    # formats.
    def reject(&block)
      @reject = block if block
      @reject
      #parts.each do |part|
      #  part.formats.reject!(&block)
      #end
    end

    # TODO: filter common and default

    # Select formats, limit the template to only the specified formats.
    def select(&block)
      @select = block if block
      @select
      #parts.each do |part|
      #  part.formats.select!(&block)
      #end
    end

    # Unrendered template parts.
    #def parts
    #  @parts
    #end

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
      body = apply_stencil(@body, data, &content)

      parts = parse_parts(body)

      parts.each do |part|
        part.formats.reject!(&@reject) if @reject
        part.formats.select!(&@select) if @select
      end

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

    # Split template header from rest of template.
    def split_text
      t = text.strip
      if t.start_with?('---')
        i = t.index('---', 3)
        h = t[0...i].strip
        b = t[i..-1]
      else
        i = t.index('---')
        if i
          h = t[0...i].strip
          b = t[i..-1]
        else
          h = nil
          b = t
        end
      end
      return h, b
    end

    # Apply stencil whole-clothe.
    def apply_stencil(body, data, &content)
      return body unless stencil
      factory.render(body, stencil, data, &content)
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
    # could present an issue with the `---` dividers.

    #
    def parse_parts(text)
      parts = text.split(/^\-\-\-/)

      #if sect.size == 1
      #  @header = {}
      #  @parts << Part.new(sect[0]) #, *[@stencil, @default].compact.flatten)
      #else
        parts.shift if parts.first.strip.empty?
      # 
      #  head = sect.shift
      #  head = YAML::load(head)
      #  parse_header(head)

      parts.map{ |part| Part.parse(part) }
    end

    #
    def load_header(header_text)
      if header_text
        YAML::load(header_text)
      else
        {}
      end
    end

    #
    def render_part(part, scope, locals={}, &content)
      formats = part.formats
      formats = default if formats.empty?
      formats = [formats, common].flatten.compact

      #case reject
      #when Array
      #  formats = formats - reject.map{|r|r.to_s}
      #when Proc
      #  formats = formats.reject(&reject)
      #end

      formats = [stencil, *formats].compact

      formats.inject(part.text) do |text, format|
        factory.render(text, format, scope, locals, &content)
      end
    end

    # Get cached {Factory} instance.
    def factory
      @factory ||= Factory.new(:tilt=>@tilt)
    end

  end

  # A part is a section of a template. Templates can be segmented into
  # parts using the '--- FORMAT' notation.
  class Part

    # Parse text body and create new part.
    def self.parse(body)
      index   = body.index("\n")
      formats = index ? body[0...index].strip : ""
      formats = formats.split(/\s+/) if String===formats
      #formats = @default if formats.empty?
      #formats.unshift(@stencil) if @stencil
      text    = body[index+1..-1]
      new(text, *formats)
    end

    # Rendering formats (html, rdoc, markdown, textile, etc.)
    attr :formats

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
    def initialize(text, *formats)
      @text     = text
      @formats  = formats
    end
  end

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

  # Controls rendering to a variety of back-end templating
  # and markup systems via Malt.
  #
  class Factory
    #
    attr :types

    # @param [Hash] options
    #
    # @option options [Array] :types
    #
    def initialize(options={})
      @types  = options[:types]
      @system = options[:system] || :malt
    end

    #
    def render(text, format, scope, locals, &content) 
      case format
      when /^coderay/
        coderay(text, format)
      when /^syntax/
        syntax(text, format)
      else
        if @system == :tilt
          render_via_tilt(text, format, scope, locals, &content)
        else
          render_via_malt(text, format, scope, locals, &content)
        end
      end
    end

    # Render via Malt.
    def render_via_malt(text, format, scope, locals, &content)
      doc = malt.text(text, :type=>format.to_sym)
      doc.render(scope, locals, &content)
    end

    # Render via Tilt.
    def render_via_tilt(text, format, scope, locals, &content)
      if engine = Tilt[format]
        #case data
        #when Hash
        #  scope = Object.new
        #  table = data
        #when Binding
        #  scope = data.eval('self')
        #  table = {}
        #else # object scope
        #  scope = data
        #  table = {}
        #end
        engine.new{text}.render(scope, locals, &content)
      else
        text
      end
    end

    # Get cached instance of Malt controller.
    #
    # @return [Malt::Machine] mutli-format renderer
    def malt
      @malt ||= (
        if types && !types.empty?
          Malt::Machine.new(:types=>types)
        else
          Malt::Machine.new
        end
      )
    end

    # Apply `coderay` syntax highlighting. This is a psuedo-format.
    def coderay(input, format)
      require 'coderay'
      format = format.split('.')[1] || :ruby #:plaintext
      tokens = CodeRay.scan(input, format.to_sym) #:ruby
      tokens.div()
    end

    # Apply `syntax` syntax highlighting. This is a psuedo-format.
    def syntax(input, format)
      require 'syntax/convertors/html'
      format = format.split('.')[1] || 'ruby' #:plaintext
      lines  = true
      conv   = Syntax::Convertors::HTML.for_syntax(format)
      conv.convert(input,lines)
    end

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

    public

    #
    def self.render(text, format, data, &content) 
      new.render(text, format, data, &content)
    end

  end

end
