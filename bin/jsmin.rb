require 'uglifier'
puts Uglifier.new.compile(File.read(ARGV[0]))