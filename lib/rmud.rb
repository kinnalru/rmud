require 'logger'
require 'active_support/all'
require 'colorize'

require 'zeitwerk'

loader = Zeitwerk::Loader.for_gem
loader.inflector.inflect(
  'rmud' => 'RMud',
  'Rmud' => 'RMud'
)
loader.setup

module RMud
end

