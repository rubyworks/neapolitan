directory = File.dirname(__FILE__)

$LOAD_PATH <<  directory + '/../lib'

require 'neapolitan'

FileUtils.install(Dir[directory + '/../fixtures/*'], '.')

When "Here is an example Neapolitan template, '(((.*?)))'" do |file, text|
  File.open(file, 'w'){ |f| f << text }
end

