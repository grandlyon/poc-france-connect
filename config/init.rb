#- -*- coding: utf-8 -*-

require 'logger'

# dir Method
def __dir__(*args)
  filename = caller[0][/^(.*):/, 1]
  dir = File.expand_path(File.dirname(filename))
  ::File.expand_path(::File.join(dir, *args.map(&:to_s)))
end

puts 'loading config/options'
require __dir__('options')
