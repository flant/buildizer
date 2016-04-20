module Buildizer
  class Packager
    autoload :MiscMod, 'buildizer/packager/misc_mod'
    autoload :ProjectSettingsMod, 'buildizer/packager/project_settings_mod'
    autoload :UserSettingsMod, 'buildizer/packager/user_settings_mod'
    autoload :CiMod, 'buildizer/packager/ci_mod'
    autoload :BuildizerConfMod, 'buildizer/packager/buildizer_conf_mod'
    autoload :PackageVersionTagMod, 'buildizer/packager/package_version_tag_mod'
    autoload :GitMod, 'buildizer/packager/git_mod'
    autoload :OvercommitMod, 'buildizer/packager/overcommit_mod'
    autoload :PackageCloudMod, 'buildizer/packager/package_cloud_mod'
    autoload :DockerCacheMod, 'buildizer/packager/docker_cache_mod'

    using Refine

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

    attr_reader :cli
    attr_reader :package_path
    attr_reader :work_path
    attr_reader :debug

    def initialize(cli)
      @cli = cli
      @package_path = Pathname.new(ENV['BUILDIZER_PATH'] || '.').expand_path
      @work_path = Pathname.new(ENV['BUILDIZER_WORK_PATH'] || '~/.buildizer').expand_path
      @debug = ENV['BUILDIZER_DEBUG'].nil? ? cli.options['debug'] : ENV['BUILDIZER_DEBUG'].to_s.on?
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

    def verify!
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
  end # Packager
end # Buildizer
