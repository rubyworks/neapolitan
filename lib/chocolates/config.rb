require 'ostruct'

module Chocolates

  # Configuration
  class Config

    #
    DEFAULTS = {
      :stencil    => 'rhtml',
      #:format     => 'html',
      :pagelayout => 'page',
      :postlayout => 'post',
      :maxchars   => 500,
    }

    attr :defaults

    def initialize
      if File.exist?('.config/defaults')
        custom_defaults = YAML.load(File.new('.config/defaults'))
      else
        custom_defaults = {}
      end
      @defaults = OpenStruct.new(DEFAULTS.merge(custom_defaults))
    end
  end

end

