require 'brite/site'

module Brite

  # Webrite command line interface.

  class Command

    def self.main(*argv)
      new(*argv).call
    end

    def initialize(*argv)
      parser.parse!(argv)
      @location = argv.shift || '.'
      @output   = nil #@argv.shift
      @noharm   = false
      @trace    = false
    end

    def parser
      OptionParser.new do |opt|
        opt.on("--trace", "show extra operational information") do
          @trace = true
        end

        opt.on("--dryrun", "-n", "don't actually write to disk") do
          @noharm = true
        end

        opt.on("--debug", "run in debug mode") do
          $DEBUG   = true
          $VERBOSE = true
        end

        opt.on_tail("--help", "display this help message") do
          puts opt
          exit
        end
      end
    end

    #
    def call
      begin
        site.build
      rescue => e
        $DEBUG ? raise(e) : puts(e.message)
      end
    end

    def site
      Site.new(
        :location => @location,
        :output   => @output,
        :noharm   => @noharm,
        :trace    => @trace
      )
    end
  end

  #
  # Command to generate a single part to standard out.
  #

  class PartCommand

    def self.start
      new.start
    end

    def initialize(argv=nil)
      @argv ||= ARGV.dup
    end

    def start
      render(parts)
    end

    # render a single part to stdout.

    def render(parts)
      $stdout << Page.new(parts).to_html
    end

  private

    def parts
      parts = []
      @argv.each do |x|
        if /^-/ =~ x
          parts << [x.sub(/-{1,2}/,'')]
        else
          parts.last < x
        end
      end
      Hash[*parts]
    end

  end

end

