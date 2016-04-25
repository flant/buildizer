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
      method_option :reset_github_token, type: :boolean, default: false,
                                         desc: "delete github token from user settings and enter new"
      method_option :require_tag, type: :boolean, default: nil,
                                  desc: "pass only git tagged commits for deploy stage"

      method_option :package_cloud, type: :array, default: nil,
                                    desc: "package cloud repo list"
      method_option :reset_package_cloud_token, type: :boolean, default: false,
                                                desc: "delete package cloud tokens " +
                                                      "from user settings for each specified repo " +
                                                      "and enter new"
      method_option :clear_package_cloud, type: :boolean, default: false,
                                          desc: "clear all package cloud settings"

      method_option :docker_cache, type: :string, default: nil,
                                   desc: "docker cache repo name in format '<org>/<name>'"
      method_option :docker_cache_user, type: :string, default: nil,
                                        desc: "docker cache login user name to access specified repo"
      method_option :docker_cache_email, type: :string, default: nil,
                                         desc: "docker cache login email to access specified repo"
      method_option :docker_cache_server, type: :string, default: nil,
                                          desc: "docker cache login server to access specified repo"
      method_option :reset_docker_cache_password, type: :boolean, default: false,
                                                  desc: "delete docker cache user password " +
                                                        "from user settings and enter new"
      method_option :clear_docker_cache, type: :boolean, default: false,
                                         desc: "clear all docker cache settings"
      def setup
        if options['verify_ci']
          buildizer.ci.configuration_actual!
        else
          buildizer.project_settings_setup!
          buildizer.user_settings_setup!
          buildizer.ci.setup!
          buildizer.package_cloud_setup!
          buildizer.docker_cache_setup!
          buildizer.overcommit_setup!
          buildizer.overcommit_verify_setup!
          buildizer.overcommit_ci_setup!
        end
      end

      desc "prepare", "Prepare images for building packages"
      shared_options
      def prepare
        buildizer.prepare
      end

      desc "build", "Build packages"
      shared_options
      def build
        buildizer.build
      end

      desc "test", "Run integration tests for packages"
      shared_options
      def test
        buildizer.test
      end

      desc "deploy", "Deploy packages"
      shared_options
      def deploy
        buildizer.deploy
      end

      desc "verify", "Verify targets params"
      shared_options
      def verify
        buildizer.verify
      end
    end # Main
  end # Cli
end # Buildizer
