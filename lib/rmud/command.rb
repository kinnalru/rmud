require 'concurrent-ruby'
require 'concurrent/promise'

module RMud
  class Command

    attr_accessor :promise, :name, :block

    def initialize(name, queue:, promise: Concurrent::Promises.resolvable_future, &block)
      @name = name
      @promise = promise
      @block = block
      @queue = queue
    end

    def run
      @block.call(self).tap do |result|
        promise.attach(result) if result.is_a?(Concurrent::Promises::AbstractEventFuture)
      end
    end

    def then(&)
      promise.then(&)
    end

    def rescue(&)
      promise.rescue(&)
    end

    def then_cmd(name, &block)
      Command.new(name, queue: @queue).tap do |cmd|
        self.then do |a, *rest|
          cmd.block = proc do |c|
            block.call(c, a, *rest)
          end
          @queue << cmd
        end
      end
    end

    def rescue_cmd(*_args, &block)
      Command.new(name, queue: @queue).tap do |cmd|
        self.rescue do |a, *rest|
          cmd.block = proc do |c|
            block.call(c, a, *rest)
          end
          @queue << cmd
        end
      end
    end

  end
end

