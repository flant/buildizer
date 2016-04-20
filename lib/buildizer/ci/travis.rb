module Buildizer
  module Ci
    class Travis < Base
      class << self
        def ci_name
          'travis'
        end

        def env_vars(prefix:, **kwargs)
          kwargs.each do |name, var_name|
            define_method("#{prefix}_#{name}_var") {repo.env_vars[var_name]}
            define_method("#{prefix}_#{name}_var_name") {var_name}
            define_method("#{prefix}_#{name}_var_delete!") do
              var = send("#{prefix}_#{name}_var")
              var.delete if var
            end
            define_method("#{prefix}_#{name}_var_update!") do |value, **kwargs|
              if value
                repo.env_vars.upsert(var_name, value, **kwargs)
              else
                send("#{prefix}_#{name}_var_delete!")
              end
            end
          end # each
        end
      end # << self

      autoload :PackageCloudMod, 'buildizer/ci/travis/package_cloud_mod'
      autoload :DockerCacheMod, 'buildizer/ci/travis/docker_cache_mod'
      autoload :PackageVersionTagMod, 'buildizer/ci/travis/package_version_tag_mod'

      include PackageCloudMod
      include DockerCacheMod
      include PackageVersionTagMod

      def setup!
        packager.write_path(conf_path, YAML.dump(actual_conf))
        require_tag_setup!
      end

      def configuration_actual?
        conf == actual_conf
      end

      def actual_conf
        install = [
          'sudo apt-get update',
          'sudo apt-get install -y apt-transport-https ca-certificates',
          'sudo apt-key adv --keyserver hkp://p80.pool.sks-keyservers.net:80 --recv-keys 58118E89F3A912897C070ADBF76221572C52609D',
          'echo "deb https://apt.dockerproject.org/repo ubuntu-trusty main" | sudo tee /etc/apt/sources.list.d/docker.list',
          'sudo apt-get update',

          # FIXME [https://github.com/docker/docker/issues/20316]:
          'sudo apt-get -o dpkg::options::="--force-confnew" install -y docker-engine=1.9.1-0~trusty',

          'echo "docker-engine hold" | sudo dpkg --set-selections',
        ]
        install.push(*Array(buildizer_install_instructions(master: packager.project_settings['master'])))

        env = packager.targets.map {|t| "BUILDIZER_TARGET=#{t}"}
        conf.merge(
          'dist' => 'trusty',
          'sudo' => 'required',
          'cache' => 'apt',
          'language' => 'ruby',
          'rvm' => '2.2.1',
          'install' => install,
          'before_script' => 'buildizer prepare',
          'script' => 'buildizer build',
          'env' => env,
          'after_success' => 'buildizer deploy',
        )
      end

      def _git_tag
        ENV['TRAVIS_TAG']
      end

      def repo_name
        if packager.git_remote_url.start_with? 'http'
          packager.git_remote_url.split('github.com/')[1]
        else
          packager.git_remote_url.split(':')[1].split('.')[0]
        end
      rescue
        raise Error, error: :input_error,
                     message: "unable to determine travis repo name " +
                              "from git remote url #{packager.git_remote_url}"
      end

      def repo
        ::Travis::Repository.find(repo_name)
      end

      def login
        @logged_in ||= begin
          packager.with_log(desc: "Login into travis") do |&fin|
            packager.user_settings['travis'] ||= {}

            if packager.cli.options['reset_github_token']
              packager.user_settings['travis'].delete('github_token')
              packager.user_settings_save!
            end

            packager.user_settings['travis']['github_token'] ||= begin
              reset_github_token = true
              packager.cli.ask("GitHub access token:", echo: false).tap{puts}
            end

            ::Travis.github_auth(packager.user_settings['travis']['github_token'])
            packager.user_settings_save! if reset_github_token

            fin.call "LOGGED IN: #{::Travis::User.current.name}"
          end # with_log

          true
        end
      end

      def with_travis(&blk)
        login
        yield
      rescue ::Travis::Client::Error => err
        raise Error, message: "travis: #{err.message}"
      end
    end # Travis
  end # Ci
end # Buildizer
