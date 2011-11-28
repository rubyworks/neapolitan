module Neapolitan

  # Command line interface.
  def self.cli(*argv)
    options = {}

    option_parser(options).parse!(argv)

    if src = options[:source]
      data = YAML.load(File.new(src))
    else
      data = {} #@source ||= YAML.load(STDIN.read)
    end

    files = argv

    begin
      files.each do |file|
        template = Template.new(File.new(file))
        if options[:output]
          #template.save(data)
        else
          puts template.render(data)
        end
      end
    rescue => e
      $DEBUG ? raise(e) : puts(e.message)
    end
  end

  # TODO: Save to output ?

  #
  def self.option_parser(options)
    require 'optparse'

    OptionParser.new do |opt|
      opt.banner = "neapolitan [file1 file2 ...]"
      #opt.on("--output", "-o [PATH]", "save output to specified directory") do |path|
      #  options[:output] = path
      #end
      opt.on("--source", "-s [FILE]", "data souce (YAML file)") do |file|
        options[:source] = file
      end
      opt.on("--tilt", "use Tilt for rendering instead of Malt") do
        options[:tilt] = true
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

end
