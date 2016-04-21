module Buildizer
  module Cli
    class Base < ::Thor
      include OptionMod

      add_shared_options(
        debug: {type: :boolean, default: false, desc: "turn on live logging for external commands"},
        color: {type: :boolean, default: true, desc: "colorized output"},
      )

      no_commands do
        def buildizer
          @buildizer ||= ::Buildizer::Buildizer.new(cli: self, **options.zymbolize_keys_deep)
        end
      end # no_commands
    end # Base
  end # Cli
end # Buildizer
