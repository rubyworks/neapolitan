require 'webrite/page'
require 'fileutils'

# = Webrite module

module Webrite

  # Site generator

  class Generator

    class NoSource < ArgumentError
      def message; "No source folder."; end
    end

    #SOURCE  = 'parts'
    SITEMAP = 'sitemap.yaml'

    RSYNC_FILTER = %{
      - .svn
      P wiki
      P robot.txt
      P statcvs
      P statsvn
      P usage
    }.gsub(/^\s*/m,'')

    # New Generator.

    def initialize(options={})
      #@source  = options[:source]  || SOURCE
      @sitemap = options[:sitemap] || SITEMAP
      @output  = options[:output]  || '.'

      @noharm = options[:noharm] || options[:dryrun]
      @trace  = options[:trace]

      #unless File.directory?(@source)
      #  raise(NoSource, "no parts source -- #{@source}")
      #end

      unless File.file?(@sitemap)
        raise(LoadError, "sitemap file not found -- #{@sitemap}")
      end

      # link vs install?
    end

    def noharm? ; @noharm ; end
    alias_method :dryrun?, :noharm?

    # Load routes.

    def routes
      @routes ||= (
        YAML::load(File.open(@sitemap))
      )
    end

    # Generate site.

    def generate
      actions = routes.collect do |page, parts|
        case page
        when '.rsync-filter'
          ['rsync', page, parts]
        else
          case parts
          #when String
          #  ['ditto', page, parts]
          when Hash
            ['page', page, parts]
          when YAML::PrivateType
            [parts.type_id, page, parts.value]
          else
            raise "Unknown target type."
          end
        end
      end

      actions.each do |action, page, parts|
        send("handle_#{action}", page, parts)
      end
    end

#     # Link handler.
#     # This is a lighter alternative to using install.
#
#     def handle_link(target, parts)
#       part, glob = parts.split(/\s+/)
#       if File.directory?(File.join(@source, part))
#         files = nil
#         Dir.chdir(File.join(@source, part)) do
#           files = Dir.glob(glob||'**/*')
#           files = files.select{|file| File.file?(file)}
#         end
#         files.each do |file|
#           src = File.join(@source, part, file)
#           dst = File.join(@output, target, file)
#           link(src, dst)
#         end
#       else
#         src = File.join(@source, part)
#         dst = File.join(@output, target)
#         link(src,dst)
#        end
#     end

#     # Rule handler.
#
#     def handle_rule(page, parts)
#       i = 0
#       page  = page.gsub('*'){ |m| '\\' + "#{i += 1}" }
#       parts = parts.gsub('*', '(.*?)')
#       regex = Regexp.new(parts)
#       files = source_files
#
#       copy = []
#       Dir.chdir(@source) do
#         files.grep(regex){ |file|
#           next unless File.file?(file)
#           dest = file.sub(regex, page)
#           copy << [file, dest]
#         }
#       end
#
#       copy.each do |src, dst|
#         src = File.join(@source, src)
#         dst = File.join(@output, dst)
#         link(src, dst)
#         #unless File.exist?(dest)
#         #  fs.mkdir_p(File.dirname(dest))
#         #  fs.ln(srce, dest)
#         #  puts "  " + dest
#         #end
#       end
#     end

    # Handle rysnc filter.

    def handle_rsync(page, parts)
      case parts
      when String
        parts = parts.strip + "\n"
        parts << "- #{@source}"
        parts << "- #{@sitemap}"
        parts << RSYNC_FILTER
      end
      Dir.chdir(@output) do
        File.open('.rsync-filter', 'w'){ |f| f << parts }
      end
    end

    # Page handler.

    def handle_page(page, parts)
      dest = File.join(@output, page)
      time = last_modified(parts.values)

      return if File.exist?(dest) && time < File.mtime(dest)

      html = Page.new(page, parts).to_html

      if noharm?
        puts "#{$0} #{dest}"
      else
        fs.mkdir_p(File.dirname(dest))
        File.open(dest,'w'){ |f| f << html }
        puts dest unless @silent
      end
    end



#     #
#
#     def source_files(glob=nil)
#       glob ||= '**/*'
#       @source_files ||= {}
#       @source_files[glob] ||= (
#         files = nil
#         Dir.chdir(@source) do
#           files = Dir.glob(glob)
#         end
#         files
#       )
#     end

    #

    def fs
      @noharm ? FileUtils::DryRun : FileUtils
    end

    #

#     def link(src, dst)
#       unless File.exist?(dst) && File.mtime(dst) >= File.mtime(src)
#         fs.mkdir_p(File.dirname(dst))
#         fs.rm(dst) if File.exist?(dst)
#         fs.ln(src, dst)
#         puts dst unless @silent
#       end
#     end

    # Returns the most recent modified time from the
    # list of source files.

    def last_modified(parts)
      files = parts.select{ |f| File.file?(f) }
      times = files.collect do |part|
        file = File.join(part)
        File.mtime(file)
      end
      times.max
    end

  end
end




#     # Straight install copy.
#     #
#     #   example: !!install
#     #     source: examples/**/*
#     #     mode:   0444
#
#     def handle_install(target, parts)
#       if Hash===parts
#         glob = parts['source']
#         mode = parts['mode']
#       else
#         glob = parts
#       end
#       files = source_files(glob)
#       files.each do |file|
#         src = File.join(@source, file)
#         dst = File.join(target, file)
#         fs.install(src, dst)
#       end
#     end
