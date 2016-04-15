module Buildizer
  module Cli
    class Main < Base
      include OptionMod
      include HelperMod

      desc "setup", "Setup buildizer"
      shared_options
      method_option :master, type: :boolean, default: nil,
                             desc: "use latest master branch of buildizer from github in ci"
      method_option :verify_ci, type: :boolean, default: false,
                                desc: "only verify ci configuration is up to date"
      def setup
        if options['verify_ci']
          raise(Error, message: "#{packager.ci.ci_name} confugration update needed") unless packager.ci.configuration_actual?
        else
          packager.project_settings_setup!
          packager.ci.setup!
          packager.overcommit_setup!
          packager.overcommit_verify_setup!
          packager.overcommit_ci_setup!
          packager.packagecloud_setup!
          packager.docker_cache_setup!
        end
      end

      desc "deinit", "Deinitialize settings (.buildizer.yml, git pre-commit hook)"
      shared_options
      def deinit
        packager.deinit!
      end

      desc "prepare", "Prepare images for building packages"
      shared_options
      def prepare
        packager.prepare!
      end

      desc "build", "Build packages"
      shared_options
      def build
        packager.build!
      end

      desc "deploy", "Deploy packages"
      shared_options
      def deploy
        packager.deploy!
      end

      desc "verify", "Verify targets params"
      shared_options
      def verify
        packager.verify!
      end
    end # Main
  end # Cli
end # Buildizer
