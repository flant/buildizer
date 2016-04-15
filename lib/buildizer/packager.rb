module Buildizer
  class Packager
    using Refine

    include MiscMod
    include ProjectSettingsMod
    include CiMod
    include ConfMod
    include GitMod
    include OvercommitMod
    include PackagecloudMod
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
