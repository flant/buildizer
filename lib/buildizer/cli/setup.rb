module Buildizer
  module Cli
    class Setup < Base
      include OptionsMod

      desc "self", "Setup buildizer options for all setup-related commands (stored in .buildizer.yml)"
      shared_options
      method_option :latest,
        type: :boolean,
        desc: "use buildizer github master branch"
      def self
        self.class.construct_packager(options).setup_options!
      end
    end # Setup
  end # Cli
end # Buildizer
