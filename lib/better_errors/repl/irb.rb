require "irb"
require "fiber"
require "tempfile"
require "mutex_m"

module BetterErrors
  module REPL
    class IRB
      extend Mutex_m

      # We have to be an ::IRB::StdioInputMethod subclass to get the #prompt
      # populated.
      class FiberInputMethod < ::IRB::StdioInputMethod
        def initialize; end

        def gets
          @previous = Fiber.yield
        end

        def encoding
          (@previous || '').encoding
        end
      end

      def initialize(binding)
        initialize_irb_session
        @input = FiberInputMethod.new
        @irb   = ::IRB::Irb.new(::IRB::WorkSpace.new(binding), @input)
        @fiber = Fiber.new { @irb.eval_input }.tap(&:resume)
        finalize_irb_session
      end

      def prompt
        [@input.prompt, ""]
      end

      def send_input(input)
        [capture { @fiber.resume("#{input}\n") }, *prompt]
      end

      private
        def initialize_irb_session(ap_path = nil)
          ::IRB.init_config(ap_path)
          ::IRB.conf[:PROMPT][:BETTER_ERRORS] = {
            PROMPT_I: ">>",
            PROMPT_N: ">>",
            PROMPT_S: "..",
            PROMPT_C: "..",
            RETURN:   "=> %s\n"
          }
          ::IRB.conf[:PROMPT_MODE] = :BETTER_ERRORS
        end

        def finalize_irb_session
          ::IRB.conf[:MAIN_CONTEXT] = @irb.context
        end

        def capture(*streams)
          streams = [$stdout, $stderr] if streams.empty?
          self.class.synchronize do
            begin
              streams_copy = streams.collect(&:dup)
              replacement  = Tempfile.new(self.class.name)
              streams.each do |stream|
                stream.reopen(replacement)
                stream.sync = true
              end
              yield
              streams.each(&:rewind)
              replacement.read
            ensure
              replacement.unlink
              streams.each_with_index do |stream, i|
                stream.reopen(streams_copy[i])
              end
            end
          end
        end
    end
  end
end
