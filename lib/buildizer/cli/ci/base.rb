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
            ask_setup_conf_file? ci.conf_path
          end
        end # no_commands
      end # Base
    end # Ci
  end # Cli
end # Buildizer
