require 'cssminify' 
puts CSSminify.compress(File.open(ARGV[0]))