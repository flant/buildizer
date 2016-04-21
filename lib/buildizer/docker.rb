module Buildizer
  class Docker
    attr_reader :builder
    attr_reader :cache

    def initialize(builder, cache: nil)
      @builder = builder
      @cache = cache
    end

    def image_klass(os_name, os_version)
      ({
        'ubuntu' => {
          '12.04' => Image::Ubuntu1204,
          '14.04' => Image::Ubuntu1404,
          '16.04' => Image::Ubuntu1604,
          nil => Image::Ubuntu1404,
        },
        'centos' => {
          'centos6' => Image::Centos6,
          'centos7' => Image::Centos7,
          nil => Image::Centos7,
        },
      }[os_name] || {})[os_version]
    end

    def new_image(os_name, os_version, **kwargs)
      klass = image_klass(os_name, os_version)
      raise Error, message: "unknown os '#{[os_name, os_version].compact.join('-')}'" unless klass
      klass.new(self, **kwargs)
    end

    def with_cache(&blk)
      builder.packager.warn "No docker cache account settings " +
                            "(BUILDIZER_DOCKER_CACHE, BUILDIZER_DOCKER_CACHE_USERNAME," +
                            " BUILDIZER_DOCKER_CACHE_PASSWORD, BUILDIZER_DOCKER_CACHE_EMAIL," +
                            " BUILDIZER_DOCKER_CACHE_SERVER) [WARN]" unless cache

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
      builder.packager.command! cmd.join(' '), desc: "Docker cache account login"
    end

    def cache_logout!
      raise Error, error: :logical_error, message: "no docker cache account info" unless cache
      builder.packager.command! 'docker logout', desc: "Docker cache account logout"
    end

    def pull_image(image)
      builder.packager.command! "docker pull #{image.base_image}", desc: "Pull docker base image #{image.base_image}"
      if cache
        pull_cache_res = builder.packager.command(
          "docker pull #{image.cache_name}",
          desc: "Try to pull docker cache image #{image.cache_name}"
        )
        if pull_cache_res.status.success?
          builder.packager.command! "docker tag -f #{image.cache_name} #{image.name}",
                                     desc: "Tag cache image #{image.cache_name}" +
                                           " as prepared build image #{image.name}"
          builder.packager.command! "docker rmi #{image.cache_name}",
                                     desc: "Remove cache image #{image.cache_name}"
        end
      end
    end

    def push_image(image)
      if cache
        builder.packager.command! "docker tag -f #{image.name} #{image.cache_name}",
                                   desc: "Tag prepared build image #{image.name}" +
                                         " as cache image #{image.cache_name}"
        builder.packager.command! "docker push #{image.cache_name}",
                                   desc: "Push cache image #{image.cache_name}"
      end
    end

    def build_image!(target)
      pull_image target.image

      target.image_work_path.join('Dockerfile').write! [*target.image.instructions, nil].join("\n")
      builder.packager.command! "docker build -t #{target.image.name} #{target.image_work_path}",
                                 desc: "Build docker image #{target.image.name}"

      push_image target.image
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

    def run_target_container!(target:, env: {})
      container = SecureRandom.uuid
      builder.packager.command! [
        "docker run --detach --name #{container}",
        *Array(_prepare_docker_params(target, env)),
        _wrap_docker_run("while true ; do sleep 1 ; done"),
      ].join(' '), desc: "Run container '#{container}' from docker image '#{target.image.name}'"
      container
    end

    def shutdown_container!(container:)
      builder.packager.command! "docker kill #{container}", desc: "Kill container '#{container}'"
      builder.packager.command! "docker rm #{container}", desc: "Remove container '#{container}'"
    end

    def run_in_container!(container:, cmd:, desc: nil)
      builder.packager.command! [
        "docker exec #{container}",
        _wrap_docker_exec(cmd),
      ].join(' '), timeout: 24*60*60, desc: desc
    end

    def run_in_image!(target:, cmd:, env: {}, desc: nil)
      builder.packager.command! [
        "docker run --rm",
        *Array(_prepare_docker_params(target, env)),
        _wrap_docker_run(cmd),
      ].join(' '), timeout: 24*60*60, desc: desc
    end

    def _prepare_docker_params(target, env)
      target.image_extra_path.mkpath
      target.image_build_path.mkpath

      [*env.map {|k,v| "-e #{k}=#{v}"},
       "-v #{builder.packager.package_path}:#{container_package_mount_path}:ro",
       "-v #{target.image_extra_path}:#{container_extra_path}:ro",
       "-v #{target.image_build_path}:#{container_build_path}",
       target.image.name]
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
