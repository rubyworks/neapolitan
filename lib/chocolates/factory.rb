require 'chocolates/part'

module Chocolates

  #
  class Factory

    # File path.
    attr :file

    # Front matter.
    attr :matter

    ## Template type (rhtml or liquid)
    #attr :stencil

    # Output extension (defualt is 'html')
    attr :extension

    # Rendering of each part.
    attr :renders

    # Rendered output.
    attr :content

    #
    def initialize(file)
      @file    = file
      @parts   = []
      @renders = []
      parse
    end

    #
    def name
      @name ||= file.chomp(File.extname(file))
    end

    ##
    #def url
    #  @url ||= '/' + name + extension
    #end

    #
    def extension
      @extension ||= '.html'
    end

    # DEPRECATE: Get rid of this and use rack to test page instead of files.
    def root
      '../' * file.count('/')
    end

    #
    def work
      '/' + File.dirname(file)
    end

    #def to_contextual_attributes
    #  { 'site'=>site.to_h, 'page'=>to_h, 'root'=>root, 'work'=>work }
    #end

    ##
    #def to_liquid
    #  to_contextual_attributes
    #end

    # Summary is the rendering of the first part.
    def summary
      @summary ||= @renders.first
    end

    #
    def render(source, &block)
      @renders = parts.map{ |part| part.render(source, &block) }
      @output  = renders.join("\n")
      @output
    end

    #
    def save(path=nil)
      raise "template has not been rendered" unless output
      path = Dir.pwd unless path
      if File.directory?(path)
        file = File.join(path, file.chomp(File.extname(file)) + extension)
      else
        file = path
      end
      if Choclates.dryrun?
        $stderr << "[DRYRUN] write #{fname}"
      else
        File.open(fname, 'w'){ |f| f << output }
      end
    end

    #
    def parts
      @parts
    end

  private

    #
    def parse
      hold = []
      text = File.read(file)
      sect = text.split(/^\-\-\-/)

      if sect.size == 1
        @matter = {}
        @parts << Part.new(sect[0], site.defaults.format)
      else
        #void = sect.shift
        head = sect.shift
        head = YAML::load(head)

        parse_header(head)

        sect.each do |body|
          index   = body.index("\n")
          format  = body[0...index].strip
          format  = site.defaults.format if format.empty?
          formats = format.split(/\s+/)
          text    = body[index+1..-1]     
          @parts << Part.new(text, *formats)
        end
      end

    end

    #
    def parse_header(head)
      @matter    = head
      @extension = head['extension']
    end

  public

    def to_s
      @output
    end

    def inspect
      "<#{self.class}: #{file}>"
    end

  end

end

