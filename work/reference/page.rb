##
#  "entia non sunt multiplicanda praeter necessitatem"
#                                        --Ockham's razor
##

begin ; require 'rubygems'  ; rescue LoadError ; end
begin ; require 'erb'       ; rescue LoadError ; end
begin ; require 'redcloth'  ; rescue LoadError ; end
begin ; require 'bluecloth' ; rescue LoadError ; end

begin
  require 'rdoc/markup/simple_markup'
  require 'rdoc/markup/simple_markup/to_html'
rescue LoadError
end

# = Webrite module

module Webrite

  # Page class renders a single page.

  class Page

    attr_reader :page

    attr_reader :main

    attr_reader :parts

    attr_reader :context

    # Accepts a raze file, which is simply a YAML map of parts,
    # that interface to the main part.

    #def self.load(file)
    #  parts = YAML.load(File.read(file))
    #  parts = parts.inject({}) do |memo, (name, part)|
    #    memo[name] = File.join(PARTS_DIR,part)
    #    memo
    #  end
    #  new(parts)
    #end

    # Shiny New Raze Page.

    def initialize(page, parts={})
      @page  = page
      @parts = parts
      @main  = parts.delete('main') #|| MAINS_ALT      TODO Add a default section for pages.yaml

      raise "missing main section" unless @main

      @context = PageContext.new(self) #, parts)
      @binding = @context.bound #instance_eval{ binding }
    end

    # Render page to html.

    def to_html
      render_file(main)
    end

    def link_rel(path)
      path
    end

    # Render part.

    def render(name)
      file = @parts[name.to_s]
      raise "bad file -- #{name}" unless file
      render_file(file)
    end

    # Render file.

    def render_file(path)
      case File.extname(path)
      #when '.raze'
      #  raze(path)
      when '.red'
        redcloth(path)
      when '.blue'
        redcloth(path)
      when '.rdoc'
        rdoc(path)
      when '.rhtml'
        eruby(path)
      when '.html'
        html(path)
      else
        raise "unknown file type"
      end
    end

    #def raze(path)
    #  parts = YAML.load(File.read(path))
    #  Raze::Page.new(parts).to_html
    #end

    def redcloth(path)
      input = File.read(path)
      RedCloth.new(input).to_html
    end

    def bluecloth(path)
      input = File.read(path)
      BlueCloth.new(input).to_html
    end

    def rdoc(path)
      markup = SM::SimpleMarkup.new
      format = SM::ToHtml.new
      input = File.read(path)
      markup.convert(input, format)
    end

    def eruby(path)
      input    = File.read(path)
      template = ERB.new(input)
      result   = template.result(@binding)  # (@binding) DOESN WORK, WHY?
      result
    end

    def html(path)
      File.read(path)
    end

  end

  #

  class PageContext

    def initialize(page)
      @page = page
    end

    #

    def render(name)
      @page.render(name)
    end

    #

    def render_file(path)
      @page.render_file(path)
    end

    #

    def part(name)
      @page.parts[name.to_s]
    end

    #

    def bound
      binding
    end

  end

end
