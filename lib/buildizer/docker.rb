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

      target.build_image_work_path.join('Dockerfile').write! [*target.build_image.instructions, nil].join("\n")
      builder.buildizer.command! "docker build -t #{target.build_image.name} #{target.build_image_work_path}",
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

    def run_in_image!(target:, cmd:, env: {}, desc: nil) # FIXME
      builder.buildizer.command! [
        "docker run --rm",
        *Array(_prepare_docker_params(target, env)),
        _wrap_docker_run(cmd),
      ].join(' '), timeout: 24*60*60, desc: desc
    end

    def _prepare_docker_params(target, env)
      target.image_extra_path.mkpath
      target.image_build_path.mkpath

      [*env.map {|k,v| "-e #{k}=#{v}"},
       "-v #{builder.buildizer.package_path}:#{container_package_mount_path}:ro",
       "-v #{target.image_extra_path}:#{container_extra_path}:ro",
       "-v #{target.image_build_path}:#{container_build_path}",
       target.build_image.name]
    end

    def _wrap_docker_exec(cmd)
      "/bin/bash -lec '#{_make_cmd(cmd)}'"
    end

    def _wrap_docker_run(cmd)
      "'#{['set -e', _make_cmd(cmd)].join('; ')}'"
    end

    def _make_cmd(cmd)
      Array(cmd).join('; ')
    end
  end # Docker
end # Buildizer
