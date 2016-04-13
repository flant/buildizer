module Buildizer
  class Packager
    using Refine

    attr_reader :package_path
    attr_reader :buildizer_conf_path
    attr_reader :options_path
    attr_reader :work_path
    attr_reader :debug
    attr_reader :ci

    def initialize(options: {}, debug: false)
      @package_path = Pathname.new(ENV['BUILDIZER_PATH'] || '.').expand_path
      @buildizer_conf_path = package_path.join('Buildizer')
      @options_path = package_path.join('.buildizer.yml')
      @work_path = Pathname.new(ENV['BUILDIZER_WORK_PATH'] || '~/.buildizer').expand_path
      @_options = options
      @_buildizer_conf = {}
      @debug = ENV['BUILDIZER_DEBUG'].nil? ? debug : ENV['BUILDIZER_DEBUG'].to_s.on?
      @ci = _construct_ci
    end

    def initialized?
      options_path.exist?
    end

    def enabled?
      !!ci.git_tag
    end

    def init!
      raise Error, error: :logical_error, message: "already initialized" if initialized?

      git_precommit_init!
      options_setup!
    end

    def deinit!
      raise Error, error: :logical_error, message: "not initialized" unless initialized?
      options_path.delete
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


    def buildizer_conf
      (@buildizer_conf ||= (YAML.load(buildizer_conf_path.read) rescue {})).tap do |res|
        @_buildizer_conf.each do |k, v|
          res[k.to_s] = v unless v.nil?
        end
      end
    end

    def buildizer_conf_update(buildizer_conf)
      @_buildizer_conf.update buildizer_conf
    end

    def buildizer_conf_setup!
      write_path(buildizer_conf_path, YAML.dump(buildizer_conf))
    end


    def options
      (@options ||= (YAML.load(options_path.read) rescue {})).tap do |res|
        @_options.each do |k, v|
          res[k.to_s] = v unless v.nil?
        end
      end
    end

    def option_set(key, value)
      @_options[key] = value
    end

    def options_setup!
      write_path(options_path, YAML.dump(options))
      @options = nil
    end


    def write_path(path, value)
      with_log(desc: path.to_s) do |&fin|
        recreate = path.exist?
        path.write value
        fin.call recreate ? "UPDATED" : "CREATED"
      end
    end

    def with_log(desc: nil, &blk)
      $stdout.write("File #{desc} ... ") if desc
      blk.call do |status|
        $stdout.write("#{status.to_s}\n") if status
      end
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

    def package_version_tag_required_for_deploy?
      ENV['BUILDIZER_REQUIRE_TAG'].to_s.on?
    end

    def package_version_tag
      ci.git_tag
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

    def package_cloud_repo
      ENV['PACKAGECLOUD'].to_s.split(',')
    end

    def package_cloud_org
      default_token = ENV['PACKAGECLOUD_TOKEN']
      package_cloud_repo.map {|repo| repo.split('/').first}.uniq.map do |org|
        [org, ENV["PACKAGECLOUD_TOKEN_#{org.upcase}"] || default_token]
      end.to_h
    end

    def package_cloud
      tokens = package_cloud_org
      package_cloud_repo.map do |repo|
        org = repo.split('/').first
        token = tokens[org]
        {org: org, repo: repo, token: token}
      end
    end

    def docker_cache
      return unless org = ENV['BUILDIZER_DOCKER_CACHE']
      {username: ENV['BUILDIZER_DOCKER_CACHE_USERNAME'],
       password: ENV['BUILDIZER_DOCKER_CACHE_PASSWORD'],
       email: ENV['BUILDIZER_DOCKER_CACHE_EMAIL'],
       server: ENV['BUILDIZER_DOCKER_CACHE_SERVER'],
       org: org}
    end

    def maintainer
      buildizer_conf['maintainer']
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

    def raw_command(*args, do_raise: false, **kwargs)
      Mixlib::ShellOut.new(*args, **kwargs).tap do |cmd|
        cmd.run_command
        if not cmd.status.success? and do_raise
          raise Error.new(error: :error, message: "external command error")
        end
      end
    end

    def raw_command!(*args, **kwargs)
      raw_command(*args, do_raise: true, **kwargs)
    end

    private

    def _construct_ci
      res = raw_command! 'git config --get remote.origin.url'
      git_remote = res.stdout.strip
      if git_remote.start_with? 'http://'
        git_url = git_remote.split('http://', 2).last
      elsif git_remote.start_with? 'https://'
        git_url = git_remote.split('https://', 2).last
      else
        git_url = git_remote.split('@', 2).last
      end

      if git_url and git_url.start_with? 'github'
        Ci::Travis.new(self)
      elsif git_url and git_url.start_with? 'gitlab'
        Ci::GitlabCi.new(self)
      end
    end
  end # Packager
end # Buildizer
