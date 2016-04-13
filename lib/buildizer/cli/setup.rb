module Buildizer
  module Cli
    class Setup < Base
      include OptionMod
      include HelperMod

      desc "all", "Setup buildizer"
      shared_options
      def all
        packager = self.class.construct_packager(options)

        version = ask("Buildizer version to use in #{packager.ci.ci_name}",
                       limited_to: ["0.0.7", "latest"],
                       default: "latest")
        packager.option_set('latest', version == 'latest')
        packager.options_setup!

        if ask_setup_conf_file? packager.buildizer_conf_path
          build_type = ask("build_type", limited_to: ["patch", "native", "fpm"])
          packager.buildizer_conf_update('build_type' => build_type)
          packager.buildizer_conf_setup!
        end

        packager.ci.setup! if packager.ci.cli.ask_setup?
      end
    end # Setup
  end # Cli
end # Buildizer
