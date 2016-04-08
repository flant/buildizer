module Buildizer
  class Docker
    attr_reader :builder
    attr_reader :username
    attr_reader :password
    attr_reader :email
    attr_reader :server

    def initialize(builder, username:, password:, email:, server: nil)
      @builder = builder
      @username = username
      @password = password
      @email = email
      @server = server
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

    def login!
      docker_login = ["docker login --email=#{email} --username=#{username} --password=#{password}"]
      docker_login << "--server=#{server}" if server
      builder.packager.command! docker_login.join(' '), desc: "Docker login"
    end

    def logout!
      builder.packager.command! 'docker logout', desc: "Docker logout"
    end

    def pull_image!(image)
      builder.packager.command "docker pull #{image.base_image}", desc: "Docker pull #{image.base_image}"
      builder.packager.command "docker pull #{image.name}", desc: "Docker pull #{image.name}"
    end

    def push_image!(image)
      builder.packager.command! "docker push #{image.name}", desc: "Docker push #{image.name}"
    end

    def build_image!(target)
      pull_image! target.image

      target.image_work_path.join('Dockerfile').write [*target.image.instructions, nil].join("\n")
      builder.packager.command! "docker build -t #{target.image.name} #{target.image_work_path}",
                                desc: "Docker build image #{target.image.name}"

      push_image! target.image
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
        *Array(_common_docker_params(target, env)),
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
      ].join(' '), desc: desc
    end

    def run_in_image!(target:, cmd:, env: {}, desc: nil)
      builder.packager.command! [
        "docker run --rm",
        *Array(_common_docker_params(target, env)),
        _wrap_docker_run(cmd),
      ].join(' '), desc: desc
    end

    def _common_docker_params(target, env)
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
