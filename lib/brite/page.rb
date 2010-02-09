require 'brite/part'

module Brite

  # Page class
  class Page

    attr :file

    # Template type (rhtml or liquid)
    attr :stencil

    # Layout name (relative filename less extension)
    attr :layout

    # Author
    attr :author

    # Title of page/post
    attr :title

    # Publish date
    attr :date

    # Tags (labels)
    attr :tags

    # Category ("a glorified tag")
    attr :category

    # rendered output text
    attr :content

    # Rendered summary. This is the rendering of the first part.
    attr :summary

    # output extension (defualt is 'html')
    attr :extension

    #
    def initialize(site, file)
      @site  = site
      @file  = file
      @parts = []
      parse
    end

    def name
      @name ||= file.chomp(File.extname(file))
    end

    #
    def url
      @url ||= name + extension
    end

    #
    def extension
      @extension ||= '.html'
    end

    #
    def root
      '../' * file.count('/')
    end

    # TODO
    #def next
    #  self
    #end

    # TODO
    #def previous
    #  self
    #end

    #
    def to_h
      {
        'url'      => url,
        'author'   => author,
        'title'    => title,
        'date'     => date,
        'tags'     => tags,
        'category' => category,
        'summary'  => summary,
        'content'  => content
      }
    end

    #
    def save(output=nil)
      output ||= Dir.pwd  # TODO
      text  = render
      fname = file.chomp(File.extname(file)) + extension
      if dryrun
        puts "[DRYRUN] write #{fname}"
      else
        puts "write #{fname}"
        File.open(fname, 'w'){ |f| f << text }
      end
    end

    def to_contextual_attributes
      { 'site'=>site.to_h, 'page'=>to_h, 'root'=>root }
    end

    #
    def to_liquid
      to_contextual_attributes
    end

  protected

    #--
    # TODO: Should validate front matter before any processing.
    #
    # TODO: Improve this code in general, what's up with output vs. content?
    #++
    def render(inherit={})
      attributes = to_contextual_attributes

      attributes = attributes.merge(inherit)

      #attributes['content'] = content if content

      output = parts.map{ |part| part.render(stencil, attributes) }

      @summary = output.first

      output = output.join("\n")

      @content = output

      #attributes = attributes.merge('content'=>output)

      if layout
        renout = site.lookup_layout(layout)
        raise "No such layout -- #{layout}" unless renout
        output = renout.render(attributes){ output }
      end

      output
    end

  private

    #
    def site
      @site
    end

    #
    def parts
      @parts
    end

    #
    def dryrun
      site.dryrun
    end

    #
    def parse
      hold = []
      text = File.read(file)
      sect = text.split(/^\-\-\-/)

      if sect.size == 1
        @prop = {}
        @parts << Part.new(sect[0], site.defaults.format)
      else
        void = sect.shift
        head = sect.shift
        head = YAML::load(head)

        parse_header(head)

        sect.each do |body|
          index   = body.index("\n")
          format  = body[0...index].strip
          format  = site.defaults.format if format.empty?
          text    = body[index+1..-1]
          @parts << Part.new(text, format)
        end
      end

    end

    #
    def parse_header(head)
      @stencil   = head['stencil'] || site.defaults.stencil
      @author    = head['author']  || 'Anonymous'
      @title     = head['title']
      @date      = head['date']
      @category  = head['category']
      @extension = head['extension']

      self.tags   = head['tags']
      self.layout = head['layout']
    end

    def layout=(layout)
      if FalseClass === layout
        @layout = nil
      else
        @layout = layout || default_layout
      end
    end

    #
    def tags=(entry)
      return entry unless entry
      case entry
      when String, Symbol
        entry = entry.to_s.strip
        if entry.index(/[,;]/)
          entry = entry.split(/[,;]/)
        else
          entry = entry.split(/\s+/)
        end
      else
        entry = entry.to_a.flatten
      end
      @tags = entry.map{ |e| e.strip }
    end

    # Default layout is different for pages vs. posts, so we
    # use this method to differntiation them.
    def default_layout
      site.defaults.pagelayout
    end

  public

    def to_s
      file
    end

    def inspect
      "<#{self.class}: #{file}>"
    end

  end

end

