module Buildizer
  class Packager
    attr_reader :package_path
    attr_reader :buildizer_conf_path
    attr_reader :options_path
    attr_reader :travis_path
    attr_reader :work_path
    attr_reader :debug

    def initialize(options: {}, debug: false)
      @package_path = Pathname.new(ENV['BUILDIZER_PATH'] || '.').expand_path
      @buildizer_conf_path = package_path.join('Buildizer')
      @options_path = package_path.join('.buildizer.yml')
      @travis_path = package_path.join('.travis.yml')
      @work_path = Pathname.new(ENV['BUILDIZER_WORK_PATH'] || '~/.buildizer').expand_path
      @_options = options
      @debug = debug
    end

    def initialized?
      options_path.exist?
    end

    def enabled?
      not (ENV['TRAVIS_TAG'] || ENV['CI_BUILD_TAG']).empty?
    end

    def init!
      raise Error, error: :logical_error, message: "already initialized" if initialized?

      git_precommit_init!
      options_setup!
      travis_setup!
    end

    def deinit!
      raise Error, error: :logical_error, message: "not initialized" unless initialized?
      options_path.delete
      git_precommit_deinit!
    end

    def update!
      travis_setup!
    end

    def prepare!
      builder.prepare
    end

    def build!
      builder.build
    end

    def deploy!
      builder.deploy
    end

    def buildizer_conf
      @buildizer_conf ||= (YAML.load((buildizer_conf_path.read rescue "")) || {})
    end

    def options
      @options ||= (YAML.load(options_path.read) rescue {}).tap do |res|
        @_options.each do |k, v|
          res[k] = v unless v.nil?
        end
      end
    end

    def options_setup!
      options_path.write YAML.dump(options)
      @options = nil
    end

    def travis
      @travis ||= (travis_path.exist? ? YAML.load(travis_path.read) : {})
    rescue Psych::Exception => err
      raise Error, error: :input_error, message: "bad travis config file #{file}: #{err.message}"
    end

    def travis_setup!
      install = [
        'sudo apt-get update',
        'sudo apt-get install -y apt-transport-https ca-certificates',
        'sudo apt-key adv --keyserver hkp://p80.pool.sks-keyservers.net:80 --recv-keys 58118E89F3A912897C070ADBF76221572C52609D',
        'echo "deb https://apt.dockerproject.org/repo ubuntu-trusty main" | sudo tee /etc/apt/sources.list.d/docker.list',
        'sudo apt-get update',
        'sudo apt-get -o dpkg::options::="--force-confnew" install -y docker-engine=1.9.1-0~trusty', # FIXME [https://github.com/docker/docker/issues/20316]
        'echo "docker-engine hold" | sudo dpkg --set-selections',
      ]
      install.push(*Array(buildizer_install_instructions(latest: options['latest'])))

      env = targets.map {|t| "BUILDIZER_TARGET=#{t}"}

      travis_path.write YAML.dump(travis.merge(
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
      @travis = nil
    end

    def git_hooks_path
      package_path.join('.git').join('hooks')
    end

    def git_old_hooks_path
      git_hooks_path.join('old-hooks')
    end

    def git_precommit_path
      git_hooks_path.join('pre-commit')
    end

    def git_old_precommit_path
      git_old_hooks_path.join('pre-commit')
    end

    def git_precommit_init!
      if git_precommit_path.exist?
        raise(Error,
          error: :logical_error,
          message: [
            "unable to backup existing precommit script: ",
            "file already exists: #{git_old_precommit_path}",
          ].join) if git_old_precommit_path.exist?
        git_old_hooks_path.mkpath
        FileUtils.cp git_precommit_path, git_old_precommit_path
      end

      git_precommit_path.write <<-EOF
#!/bin/bash
buildizer update
git add -v .travis.yml
      EOF
      git_precommit_path.chmod 0755
    end

    def git_precommit_deinit!
      git_precommit_path.delete if git_precommit_path.exist?
      FileUtils.cp git_old_precommit_path, git_precommit_path if git_old_precommit_path.exist?
      git_old_hooks_path.rmtree if git_old_hooks_path.exist?
    end

    def package_name
      buildizer_conf['package_name']
    end

    def package_version
      buildizer_conf['package_version']
    end

    def package_version_tag
      ENV['TRAVIS_TAG'] || ENV['CI_BUILD_TAG']
    end

    def os_params(os)
      buildizer_conf['os'].to_h[os.to_s].to_h
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

    def docker_server
      buildizer_conf['docker_server']
    end

    def docker_image
      buildizer_conf['image']
    end

    def package_cloud
      buildizer_conf['package_cloud']
    end

    def package_cloud_token
      ENV['PACKAGECLOUD_TOKEN'] || begin
        raise Error, error: :input_error, message: "PACKAGECLOUD_TOKEN env variable required"
      end
    end

    def docker_username
      ENV['BUILDIZER_DOCKER_USERNAME'] || begin
        raise Error, error: :input_error, message: "BUILDIZER_DOCKER_USERNAME env variable required"
      end
    end

    def docker_password
      ENV['BUILDIZER_DOCKER_PASSWORD'] || begin
        raise Error, error: :input_error, message: "BUILDIZER_DOCKER_PASSWORD env variable required"
      end
    end

    def docker_email
      ENV['BUILDIZER_DOCKER_EMAIL'] || begin
        raise Error, error: :input_error, message: "BUILDIZER_DOCKER_EMAIL env variable required"
      end
    end

    def builder
      @builder ||= begin
        build_type = buildizer_conf['build_type']
        raise Error, error: :input_error, message: "no build_type given" unless build_type
        klass = {fpm: Builder::Fpm,
                 native: Builder::Native}[build_type.to_s.to_sym]
        raise Error, error: :input_error, message: "unknown build_type '#{build_type}'" unless klass
        klass.new(self)
      end
    end

    def buildizer_install_instructions(latest: nil)
      if latest
        ['git clone https://github.com/flant/buildizer ~/buildizer',
         'echo "export BUNDLE_GEMFILE=~/buildizer/Gemfile" | tee -a ~/.bashrc',
         'export BUNDLE_GEMFILE=~/buildizer/Gemfile',
         'gem install bundler',
         'bundle install',
        ]
      else
        'gem install buildizer'
      end
    end

    def command(*args, do_raise: false, **kwargs)
      Shellfold.run(*args, live_log: debug, **kwargs).tap do |cmd|
        if not cmd.status.success? and do_raise
          raise Error.new(error: :error, message: "external command error")
        end
      end
    end

    def command!(*args, **kwargs)
      command(*args, do_raise: true, log_failure: true, **kwargs)
    end
  end # Packager
end # Buildizer
