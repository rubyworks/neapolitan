require 'neapolitan'

module Neapolitan

  # Command line interface.

  class Command

    def self.main(*argv)
      new(*argv).call
    end

    def initialize(*argv)
      @output    = nil
      @noharm    = false
      @trace     = false
      @data_file = nil

      parser.parse!(argv)

      @files = argv
    end

    def parser
      OptionParser.new do |opt|
        opt.banner = "neapolitan [file1 file2 ...]"

        opt.on("--output", "-o [PATH]", "save output to specified directory") do |path|
          @output = path
        end

        opt.on("--source", "-s [FILE]", "source data file") do |file|
          @data_file = file
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
        @files.each do |file|
          doc = Document.new(file, data)
          if @output
            #doc.save
          else
            puts doc
          end
        end
      rescue => e
        $DEBUG ? raise(e) : puts(e.message)
      end
    end

    #
    def data
      if @data_file
        YAML.load(File.new(@data_file))
      else
        {} #@source ||= YAML.load(STDIN.read)
      end
    end

  end

end

