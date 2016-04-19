module Buildizer
  module Cli
    class Main < Base
      include OptionMod

      desc "setup", "Setup buildizer"
      shared_options
      method_option :master, type: :boolean, default: nil,
                             desc: "use latest master branch of buildizer from github in ci"
      method_option :verify_ci, type: :boolean, default: false,
                                desc: "only verify ci configuration is up to date"
      method_option :package_cloud, type: :array, default: nil,
                                    desc: "package cloud repo list"
      method_option :reset_github_token, type: :boolean, default: false,
                                         desc: "delete github token from user settings and enter new"
      method_option :reset_package_cloud_token, type: :boolean, default: false,
                                                desc: "delete package cloud tokens " +
                                                      "from user settings for each specified repo " +
                                                      "and enter new"
      method_option :require_tag, type: :boolean, default: nil,
                                  desc: "pass only git tagged commits for deploy stage"
      method_option :docker_cache, type: :string, default: nil,
                                   desc: "docker cache repo name in format '<org>/<name>'"
      method_option :docker_cache_user, type: :string, default: nil,
                                        desc: "docker cache user name to access specified repo"
      method_option :docker_cache_email, type: :string, default: nil,
                                         desc: "docker cache email to access specified repo"
      method_option :reset_docker_cache_password, type: :boolean, default: false,
                                                  desc: "delete docker cache user password " +
                                                        "from user settings and enter new"
      def setup
        if options['verify_ci']
          raise(Error, message: "#{packager.ci.ci_name} confugration update needed") unless packager.ci.configuration_actual?
        else
          packager.project_settings_setup!
          packager.user_settings_setup!
          packager.ci.setup!
          packager.package_cloud_setup!
          packager.docker_cache_setup!
          packager.overcommit_setup!
          packager.overcommit_verify_setup!
          packager.overcommit_ci_setup!
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
