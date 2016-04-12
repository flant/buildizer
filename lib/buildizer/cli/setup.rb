module Buildizer
  module Cli
    class Setup < Base
      include OptionsMod

      desc "self", "Setup buildizer options for all setup-related commands (stored in .buildizer.yml)"
      shared_options
      def self
        puts 'hello'
      end
    end # Setup
  end # Cli
end # Buildizer
