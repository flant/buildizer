module Buildizer
  module Cli
    class Setup < Base
      include OptionMod
      include HelperMod

      add_stored_options(
        ci: {type: :string, default: nil,
             desc: "explicitly set ci to use (auto detect by default based on git remote url)"},
        latest: {type: :boolean, default: nil,
                 desc: "use latest buildizer from github in ci"},
      )

      desc "all", "Setup buildizer"
      shared_options
      stored_option :ci
      stored_option :latest
      def all
        packager = self.class.construct_packager(options)

        if ask_setup_conf_file? packager.options_path
          version = ask("Buildizer version to use in #{packager.ci.ci_name}",
                         limited_to: ["0.0.7", "latest"],
                         default: ((packager.options['latest'] == false) ? '0.0.7' : "latest"))
          packager.option_set('latest', version == 'latest')
          packager.option_set('ci', packager.ci.ci_name)
          packager.options_setup!
        end

        if ask_setup_conf_file? packager.buildizer_conf_path
          default_build_type = packager.buildizer_conf['build_type']
          build_type = ask("build_type",
                            limited_to: ["patch", "native", "fpm"],
                            default: default_build_type)
          packager.buildizer_conf_update('build_type' => build_type)
          packager.buildizer_conf_setup!
        end

        packager.ci.setup! if packager.ci.cli.ask_setup?

        if packager.git_available? and ask_yes_no?("Do setup overcommit?", default: true)
          packager.overcommit_setup!
          packager.overcommit_verify_setup!
          packager.overcommit_ci_setup!
        end
      end

      desc "ci", "Setup buildizer ci configuration"
      shared_options
      stored_option :ci
      stored_option :latest
      method_option :verify, type: :boolean, default: false,
                             desc: "only verify ci configuration is up to date"
      def ci
        packager = self.class.construct_packager(options)
        if not options['verify']
          packager.ci.setup!
        elsif not packager.ci.configuration_actual?
          raise Error, error: :error, message: "#{packager.ci.ci_name} confugration update needed"
        end
      end
    end # Setup
  end # Cli
end # Buildizer
