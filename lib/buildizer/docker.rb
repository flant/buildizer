module Buildizer
  class Docker
    attr_reader :builder
    attr_reader :cache

    def initialize(builder, cache: nil)
      @builder = builder
      @cache = cache
    end

    def os_klass(os_name, os_version)
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
      }[os_name] || {})[os_version]
    end

    def new_os(os_name, os_version, **kwargs)
      klass = os_klass(os_name, os_version)
      raise Error, message: "unknown os '#{[os_name, os_version].compact.join('-')}'" unless klass
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

    def pull_image(os) #FIXME
      builder.buildizer.command! "docker pull #{os.base_image}", desc: "Pull docker base os #{os.base_image}"
      if cache
        pull_cache_res = builder.buildizer.command(
          "docker pull #{os.cache_name}",
           desc: "Try to pull docker cache image #{os.cache_name}"
        )
        if pull_cache_res.status.success?
          builder.buildizer.command! "docker tag -f #{os.cache_name} #{os.build_image_name}",
                                      desc: "Tag cache image #{os.cache_name}" +
                                            " as prepared build image #{os.build_image_name}"
          builder.buildizer.command! "docker rmi #{os.cache_name}",
                                      desc: "Remove cache image #{os.cache_name}"
        end
      end
    end

    def push_image(os) #FIXME
      if cache
        builder.buildizer.command! "docker tag -f #{os.build_image_name} #{os.cache_name}",
                                    desc: "Tag prepared build image #{os.build_image_name}" +
                                          " as cache image #{os.cache_name}"
        builder.buildizer.command! "docker push #{os.cache_name}",
                                    desc: "Push cache image #{os.cache_name}"
      end
    end

    def build_image!(target) # FIXME
      pull_image target.os

      target.image_work_path.join('Dockerfile').write! [*target.os.instructions, nil].join("\n")
      builder.buildizer.command! "docker build -t #{target.os.build_image_name} #{target.image_work_path}",
                                  desc: "Build docker image #{target.os.build_image_name}"

      push_image target.os
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
       target.os.build_image_name]
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
