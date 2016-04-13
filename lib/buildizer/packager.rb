module Buildizer
  class Packager
    using Refine

    include MiscMod
    include OptionsMod
    include CiMod
    include ConfMod

    attr_reader :package_path
    attr_reader :work_path
    attr_reader :debug

    def initialize(debug: false)
      @package_path = Pathname.new(ENV['BUILDIZER_PATH'] || '.').expand_path
      @work_path = Pathname.new(ENV['BUILDIZER_WORK_PATH'] || '~/.buildizer').expand_path
      @debug = ENV['BUILDIZER_DEBUG'].nil? ? debug : ENV['BUILDIZER_DEBUG'].to_s.on?
    end

    def init!
      raise Error, error: :logical_error, message: "already initialized" if initialized?

      git_precommit_init!
    end

    def deinit!
      raise Error, error: :logical_error, message: "not initialized" unless initialized?
      git_precommit_deinit!
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

    def builder
      @builder ||= begin
        build_type = buildizer_conf['build_type']
        raise Error, error: :input_error, message: "build_type is not defined" unless build_type
        klass = {fpm: Builder::Fpm,
                 native: Builder::Native,
                 patch: Builder::Patch}[build_type.to_s.to_sym]
        raise Error, error: :input_error, message: "unknown build_type '#{build_type}'" unless klass
        klass.new(self)
      end
    end
  end # Packager
end # Buildizer
