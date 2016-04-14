module Buildizer
  module Cli
    module Ci
      class Base < ::Thor
        include HelperMod

        attr_reader :ci

        def initialize(ci)
          @ci = ci
        end

        no_commands do
          def ask_setup?
            (not ci.configuration_actual?) and
              ask_yes_no?("Configuration change needed for #{ci.ci_name}. Do setup?", default: true)
          end
        end # no_commands
      end # Base
    end # Ci
  end # Cli
end # Buildizer
