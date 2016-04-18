module Buildizer
  module Ci
    class Travis < Base
      def setup!
        packager.write_path(conf_path, YAML.dump(actual_conf))
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

      def travis_repo_name
        packager.git_remote_url.split(':')[1].split('.')[0]
      rescue
        raise Error, error: :input_error,
                     message: "unable to determine travis repo name " +
                              "from git remote url #{packager.git_remote_url}"
      end

      def travis_repo
        ::Travis::Repository.find(travis_repo_name)
      end

      def travis_packagecloud_var_name
        'PACKAGECLOUD'
      end

      def travis_packagecloud_var
        travis_repo.env_vars[travis_packagecloud_var_name]
      end

      def travis_packagecloud_var_upsert(**kwargs)
        travis_repo.env_vars.upsert(travis_packagecloud_var_name, kwargs.delete(:value), **kwargs)
      end

      def travis_packagecloud_token_var_name(org: nil)
        if org
          "PACKAGECLOUD_TOKEN_#{org.upcase}"
        else
          'PACKAGECLOUD_TOKEN'
        end
      end

      def travis_packagecloud_token_var(org: nil)
        travis_repo.env_vars[travis_packagecloud_token_var_name(org: org)]
      end

      def travis_packagecloud_token_var_upsert(**kwargs)
        travis_repo.env_vars.upsert(travis_packagecloud_token_var_name(org: kwargs.delete(:org)),
                                    kwargs.delete(:value),
                                    **kwargs)
      end

      def travis_packagecloud_repo_list
        travis_packagecloud_var.value.split(',')
      end

      def packagecloud_setup!
        with_travis do
          packager.with_log(desc: "Travis packagecloud repo list") do |&fin|
            travis_packagecloud_var_upsert(value: packager.packagecloud_repo_list.uniq.join(','),
                                           public: true)
            fin.call 'UPSERTED'
          end # with_log

          packager.packagecloud_org_desc_list.each do |desc|
            next unless desc[:token]
            packager.with_log(desc: "Travis packagecloud token for '#{desc[:org]}'") do |&fin|
              travis_packagecloud_token_var_upsert(org: desc[:org], value: desc[:token], public: false)
              fin.call 'UPSERTED'
            end # with_log
          end
        end # with_travis
      end

      def with_travis(&blk)
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

          fin.call "OK: #{::Travis::User.current.name}"
        end # with_log

        yield
      rescue ::Travis::Client::Error => err
        raise Error, message: "travis: #{err.message}"
      end

      class << self
        def ci_name
          'travis'
        end
      end # << self
    end # Travis
  end # Ci
end # Buildizer
