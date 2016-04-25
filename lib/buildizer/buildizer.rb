module Buildizer
  class Buildizer
    autoload :MiscMod, 'buildizer/buildizer/misc_mod'
    autoload :ProjectSettingsMod, 'buildizer/buildizer/project_settings_mod'
    autoload :UserSettingsMod, 'buildizer/buildizer/user_settings_mod'
    autoload :CiMod, 'buildizer/buildizer/ci_mod'
    autoload :BuildizerConfMod, 'buildizer/buildizer/buildizer_conf_mod'
    autoload :PackageVersionTagMod, 'buildizer/buildizer/package_version_tag_mod'
    autoload :GitMod, 'buildizer/buildizer/git_mod'
    autoload :OvercommitMod, 'buildizer/buildizer/overcommit_mod'
    autoload :PackageCloudMod, 'buildizer/buildizer/package_cloud_mod'
    autoload :DockerCacheMod, 'buildizer/buildizer/docker_cache_mod'

    include MiscMod
    include ProjectSettingsMod
    include UserSettingsMod
    include CiMod
    include BuildizerConfMod
    include PackageVersionTagMod
    include GitMod
    include OvercommitMod
    include PackageCloudMod
    include DockerCacheMod

    attr_reader :options
    attr_reader :package_path
    attr_reader :work_path
    attr_reader :debug

    def initialize(cli: nil, **kwargs)
      @cli = cli
      @options = kwargs
      @package_path = Pathname.new(ENV['BUILDIZER_PATH'] || '.').expand_path
      @work_path = Pathname.new(ENV['BUILDIZER_WORK_PATH'] || '~/.buildizer').expand_path
      @debug = ENV['BUILDIZER_DEBUG'].nil? ? options[:debug] : ENV['BUILDIZER_DEBUG'].to_s.on?
      @color = interactive? ? options[:color] : false
    end

    def interactive?
      @cli and $stdout.isatty
    end

    def secure_option(name, ask: nil, default: nil)
      if interactive? and ask
        @cli.ask(ask, echo: false, default: default).tap{puts}
      else
        options.fetch(name.to_sym, default)
      end
    end

    def prepare
      builder.prepare
    end

    def build
      builder.build
    end

    def test
      builder.test
    end

    def deploy
      builder.deploy
    end

    def verify
      builder.verify
    end

    def builder
      @builder ||= begin
        build_type = buildizer_conf['build_type']
        raise Error, error: :input_error, message: "Buildizer build_type is not defined" unless build_type
        klass = {fpm: Builder::Fpm,
                 native: Builder::Native,
                 patch: Builder::Patch}[build_type.to_s.to_sym]
        raise Error, error: :input_error, message: "unknown build_type '#{build_type}'" unless klass
        klass.new(self)
      end
    end
  end # Buildizer
end # Buildizer
