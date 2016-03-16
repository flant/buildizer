module Buildizer
  class Docker
    include Concern

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
      command! docker_login.join(' ')
    end

    def logout!
      command! 'docker logout'
    end

    def pull_image!(image)
      command "docker pull #{image.base_image}"
      command "docker pull #{image.name}"
    end

    def push_image!(image)
      command! "docker push #{image.name}"
    end

    def build_image!(image)
      pull_image! image

      image_build_path(image).join('Dockerfile').write [*image.instructions, nil].join("\n")
      command! "docker build -t #{image.name} #{image_build_path(image)}"

      push_image! image
    end

    def image_build_path(image)
      builder.build_path.join(image.os_name).join(image.os_version)
    end

    def image_runtime_build_path(image)
      image_build_path(image).join('build')
    end

    def container_package_path
      Pathname.new('/package')
    end

    def container_build_path
      container_package_path.join('build')
    end

    def run!(image, cmd:, env: {})
      cmd = Array(cmd)

      command! p [
        "docker run --rm",
        *env.map {|k,v| "-e #{k}=#{v}"},
        "-v #{builder.packager.package_path}:#{container_package_path}",
        "-v #{image_runtime_build_path(image)}:#{container_build_path}",
        image.name,
        "'#{cmd.join('; ')}'"
      ].join(' ')
    end
  end # Docker
end # Buildizer
