module Buildizer
  class Docker
    attr_reader :builder
    attr_reader :cache

    def initialize(builder, cache: nil)
      @builder = builder
      @cache = cache
    end

    def os_klass(name, version)
      ({
        'ubuntu' => {
          '12.04' => Os::Ubuntu1204,
          '14.04' => Os::Ubuntu1404,
          '16.04' => Os::Ubuntu1604,
          nil => Os::Ubuntu1404,
        },
        'centos' => {
          'centos6' => Os::Centos6,
          'centos7' => Os::Centos7,
          nil => Os::Centos7,
        },
      }[name] || {})[version]
    end

    def new_os(name, version, **kwargs)
      klass = os_klass(name, version)
      raise Error, message: "unknown os '#{[name, version].compact.join('-')}'" unless klass
      klass.new(self, **kwargs)
    end

    def with_cache(&blk)
      builder.buildizer.warn "No docker cache account settings " +
                             "(BUILDIZER_DOCKER_CACHE, BUILDIZER_DOCKER_CACHE_USERNAME," +
                             " BUILDIZER_DOCKER_CACHE_PASSWORD, BUILDIZER_DOCKER_CACHE_EMAIL," +
                             " BUILDIZER_DOCKER_CACHE_SERVER)" unless cache

      cache_login! if cache
      begin
        yield if block_given?
      ensure
        cache_logout! if cache
      end
    end

    def cache_login!
      raise Error, error: :logical_error, message: "no docker cache account info" unless cache

      cmd = ["docker login"]
      cmd << "--email=#{cache[:email]}" if cache[:email]
      cmd << "--username=#{cache[:user]}" if cache[:user]
      cmd << "--password=#{cache[:password]}" if cache[:password]
      cmd << "--server=#{cache[:server]}" if cache[:server]
      builder.buildizer.command! cmd.join(' '), desc: "Docker cache account login"
    end

    def cache_logout!
      raise Error, error: :logical_error, message: "no docker cache account info" unless cache
      builder.buildizer.command! 'docker logout', desc: "Docker cache account logout"
    end

    def pull_cache_image(build_image, cache_image)
      pull_cache_res = builder.buildizer.command(
        "docker pull #{cache_image.name}",
         desc: "Try to pull docker cache image #{cache_image.name}"
      )
      if pull_cache_res.status.success?
        builder.buildizer.command! "docker tag -f #{cache_image.name} #{build_image.name}",
                                    desc: "Tag cache image #{cache_image.name}" +
                                          " as prepared build image #{build_image.name}"
        builder.buildizer.command! "docker rmi #{cache_image.name}",
                                    desc: "Remove cache image #{cache_image.name}"
      end
    end

    def cache_build_image(build_image, cache_image)
      builder.buildizer.command! "docker tag -f #{build_image.name} #{cache_image.name}",
                                  desc: "Tag prepared build image #{build_image.name}" +
                                        " as cache image #{cache_image.name}"
      builder.buildizer.command! "docker push #{cache_image.name}",
                                  desc: "Push cache image #{cache_image.name}"
    end

    def make_build_image(target)
      pull_cache_image(target.build_image, target.cache_image) if target.cache_image

      target.build_image.dockerfile_write!

      builder.buildizer.command! "docker build " +
                                 "-t #{target.build_image.name} " +
                                 "-f #{target.build_image.dockerfile_path} " +
                                 "#{target.build_image.dockerfile_path.dirname}",
                                  desc: "Build docker image #{target.build_image.name}"

      cache_build_image(target.build_image, target.cache_image) if target.cache_image
    end

    def container_package_path
      Pathname.new('/package')
    end

    def container_package_archive_path
      Pathname.new('/package.tar.gz')
    end

    def container_package_mount_path
      Pathname.new('/.package')
    end

    def container_build_path
      Pathname.new('/build')
    end

    def container_extra_path
      Pathname.new('/extra')
    end

    def run_container!(name: nil, image:, env: {}, desc: nil, privileged: nil)
      (name || SecureRandom.uuid).tap do |name|
        builder.buildizer.command! [
          "docker run --detach --name #{name}",
          *Array(_prepare_command_params(privileged: privileged)),
          *Array(_prepare_container_params(image, env: env)),
          _wrap_docker_command("while true ; do sleep 1 ; done"),
        ].join(' '), desc: desc
      end
    end

    def shutdown_container!(container:)
      builder.buildizer.command! "docker kill #{container}", desc: "Kill container '#{container}'"
      builder.buildizer.command! "docker rm #{container}", desc: "Remove container '#{container}'"
    end

    def with_container(**kwargs, &blk)
      container = run_container!(**kwargs)
      begin
        yield container if block_given?
      ensure
        shutdown_container!(container: container)
      end
    end

    def run_in_container(container:, cmd:, desc: nil, cmd_opts: {}, privileged: nil)
      builder.buildizer.command [
        "docker exec #{container}",
        *Array(_prepare_command_params(privileged: privileged)),
        _wrap_docker_command(cmd),
      ].join(' '), timeout: 24*60*60, desc: desc, **cmd_opts
    end

    def run_in_container!(cmd_opts: {}, **kwargs)
      cmd_opts[:do_raise] = true
      cmd_opts[:log_failure] = true
      run_in_container(cmd_opts: cmd_opts, **kwargs)
    end

    def run_in_image(image:, cmd:, env: {}, desc: nil, cmd_opts: {}, privileged: nil)
      builder.buildizer.command [
        "docker run --rm",
        *Array(_prepare_command_params(privileged: privileged)),
        *Array(_prepare_container_params(image, env: env)),
        _wrap_docker_command(cmd),
      ].join(' '), timeout: 24*60*60, desc: desc, **cmd_opts
    end

    def run_in_image!(cmd_opts: {}, **kwargs)
      cmd_opts[:do_raise] = true
      run_in_image(cmd_opts: cmd_opts, **kwargs)
    end

    def _prepare_container_params(image, env: {})
      image.extra_path.mkpath
      image.build_path.mkpath

      [*env.map {|k,v| "-e #{k}=#{v}"},
       "-v #{builder.buildizer.package_path}:#{container_package_mount_path}:ro",
       "-v #{image.extra_path}:#{container_extra_path}:ro",
       "-v #{image.build_path}:#{container_build_path}",
       image.name].compact
    end

    def _prepare_command_params(privileged: nil)
      (privileged == true) ? "--privileged=true" : nil
    end

    def _wrap_docker_command(cmd)
      "/bin/bash -lec '#{_make_cmd(cmd)}'"
    end

    def _make_cmd(cmd)
      Array(cmd).join('; ')
    end
  end # Docker
end # Buildizer
