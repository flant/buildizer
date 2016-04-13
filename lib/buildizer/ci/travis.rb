module Buildizer
  module Ci
    class Travis < Base
      def setup!
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
        install.push(*Array(buildizer_install_instructions(latest: packager.options['latest'])))

        env = packager.targets.map {|t| "BUILDIZER_TARGET=#{t}"}
        conf_raw = YAML.dump(conf.merge(
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
        ))
        packager.write_path(conf_path, conf_raw)

        @conf = nil
      end

      def _git_tag
        ENV['TRAVIS_TAG']
      end

      class << self
        def ci_name
          'travis'
        end
      end # << self
    end # Travis
  end # Ci
end # Buildizer
