# Shell script used to generate Yard documentation from Tomdoc
#
# install - install dependencies.
# server  - generate documentation and run the local server.

if ARGV[0] == 'install'
  puts `gem install yard`
  puts `gem install yard-tomdoc`
elsif ARGV[0] == 'server'
  puts 'Generating doc...'
  puts system("yardoc 'lib/' --protected --private --plugin yard-tomdoc")
  puts 'Yard server running on port :8808'
  `yard server`
end
