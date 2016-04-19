module Buildizer
  class Packager
    module BuildizerConfMod
      using Refine

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
        write_path(buildizer_conf_path, YAML.dump(buildizer_conf))
      end

      def package_name
        buildizer_conf['package_name']
      end

      def package_version
        buildizer_conf['package_version']
      end

      def before_prepare
        Array(buildizer_conf['before_prepare'])
      end

      def after_prepare
        Array(buildizer_conf['after_prepare'])
      end

      def targets
        targets = Array(buildizer_conf['target'])
        restrict_targets = ENV['BUILDIZER_TARGET']
        restrict_targets = restrict_targets.split(',').map(&:strip) if restrict_targets
        targets = targets & restrict_targets if restrict_targets
        targets
      end

      def prepare
        Array(buildizer_conf['prepare'])
      end

      def build_dep
        Array(buildizer_conf['build_dep']).to_set
      end

      def before_build
        Array(buildizer_conf['before_build'])
      end

      def maintainer
        buildizer_conf['maintainer']
      end
    end # BuildizerConfMod
  end # Packager
end # Buildizer
