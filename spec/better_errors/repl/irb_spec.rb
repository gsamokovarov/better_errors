require "spec_helper"
require "irb"
require "better_errors/repl/irb"
require "better_errors/repl/shared_examples"

module BetterErrors
  module REPL
    describe IRB do
      let(:fresh_binding) {
        local_a = 123
        binding
      }

      let(:repl) { IRB.new fresh_binding }

      it "does line continuation" do
        output, prompt, filled = repl.send_input ""
        output.should == "=> nil\n"
        prompt.should == ">>"
        filled.should == ""

        output, prompt, filled = repl.send_input "def f(x)"
        output.should == ""
        prompt.should == ".."
        filled.should == "  "

        output, prompt, filled = repl.send_input "end"
        output.should == "=> nil\n"
        prompt.should == ">>"
        filled.should == ""
      end

      it_behaves_like "a REPL provider"
    end
  end
end
