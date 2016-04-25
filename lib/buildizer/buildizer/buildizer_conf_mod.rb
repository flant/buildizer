module Buildizer
  class Buildizer
    module BuildizerConfMod
      def buildizer_conf_path
        package_path.join('Buildizer')
      end

      def buildizer_conf
        @buildizer_conf ||= buildizer_conf_path.load_yaml
      end

      def buildizer_conf_update(conf)
        buildizer_conf.update conf
      end

      def buildizer_conf_setup!
        write_yaml(buildizer_conf_path, buildizer_conf)
      end
    end # BuildizerConfMod
  end # Buildizer
end # Buildizer
