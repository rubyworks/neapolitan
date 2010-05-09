require 'chocolates'

module Chocolates

  # Command line interface.

  class Command

    def self.main(*argv)
      new(*argv).call
    end

    def initialize(*argv)
      parser.parse!(argv)
      @files    = argv
      @output   = nil
      @noharm   = false
      @trace    = false
    end

    def parser
      OptionParser.new do |opt|
        opt.banner = "chocolates [file1 file2 ...]"

        opt.on("--output", "-o [PATH]", "save output to specified directory") do |path|
          @output = path
        end

        opt.on("--source", "-s [FILE]", "source data file" do |file|
          @source_file = file
        end

        opt.on("--trace", "show extra operational information") do
          $TRACE = true
        end

        opt.on("--dryrun", "-n", "don't actually write to disk") do
          $DRYRUN = true
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
        files.each do |file|
          factory = Factory.new(file)
          factory.render(source)
          if @output
            factory.
          else
            factory
          end
        end
      rescue => e
        $DEBUG ? raise(e) : puts(e.message)
      end
    end

    #
    def source
      if @source_file
        @source ||= YAML.load(@source_file)
      else
        @source ||= YAML.load(ARGF.read)
      end
    end

  end

end

