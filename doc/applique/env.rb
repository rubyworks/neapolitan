When "Here is an example Neapolitan template, '(((.*?)))'" do |file, text|
  File.open(file, 'w'){ |f| f << text }
end

