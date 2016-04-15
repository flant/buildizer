module Buildizer
  module Cli
    class Base < ::Thor
      include OptionMod

      add_shared_options(
        debug: {type: :boolean, default: false, desc: "turn on live logging for external commands"},
      )

      no_commands do
        def packager
          @packager ||= Buildizer::Packager.new(self)
        end
      end # no_commands
    end # Base
  end # Cli
end # Buildizer
