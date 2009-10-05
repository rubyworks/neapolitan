##
#  "entia non sunt multiplicanda praeter necessitatem"
#                                        --Ockham's razor
##

require 'brite/config'
require 'brite/page'
require 'brite/post'
require 'brite/layout'
require 'brite/template'

#
module Brite

  # Site class
  class Site

    # Location of site.
    attr :location
    attr :output

    attr :layouts
    attr :pages
    attr :posts

    attr :dryrun
    attr :verbose

    def initialize(options={})
      @location = options[:location] || Dir.pwd
      @output   = options[:output]   || Dir.pwd
      @dryrun   = options[:dryrun]

      @layouts = []
      @pages   = []
      @posts   = []
    end

    def tags
      @tags ||= posts.map{ |p| p.tags }.flatten.uniq.sort
    end

    def posts_by_tag
      @posts_by_tag ||= (
        chart ||= Hash.new{|h,k|h[k]=[]}
        posts.each do |post|
          post.tags.each do |tag|
            chart[tag] << post
          end
        end
        chart
      )
    end

    def verbose?
      true
    end

    def build
      Dir.chdir(location) do
        sort_files
        if verbose?
          puts "Layouts: " + layouts.join(", ")
          puts "Pages:   " + pages.join(", ")
          puts "Posts:   " + posts.join(", ")
          puts
        end
        render
      end
    end

    def lookup_layout(name)
      layouts.find{ |l| name == l.name }
    end

    def sort_files
      files = Dir['**/*']
      files.each do |file|
        temp = false
        name = File.basename(file)
        ext  = File.extname(file)
        case ext
        when '.layout'
          layouts << Layout.new(self, file)
        when '.page' #*%w{.markdown .rdoc .textile .whtml}
          pages << Page.new(self, file)
        when '.post'
          posts << Post.new(self, file)
        end
      end
      posts.sort!{ |a,b| b.date <=> a.date }
    end

    def render
      render_posts  # renger posts first, so pages can use them
      render_pages
    end

    def render_pages
      pages.each do |page|
        page.save(output)
      end
    end

    def render_posts
      posts.each do |post|
        post.save(output)
      end
    end

    def config
      @config ||= Config.new
    end

    def defaults
      config.defaults
    end

    def to_h
      pbt = {}
      posts_by_tag.each do |tag, posts|
        pbt[tag] = posts.map{ |p| p.to_h }
      end
      {
        'posts' => posts.map{ |p| p.to_h },
        'posts_by_tag' => pbt, #posts_by_tag, #.map{ |t, ps| [t, ps.map{|p|p.to_h}] }
        'tags' => tags
      }
    end

    def to_liquid
      to_h
    end

  end

end
