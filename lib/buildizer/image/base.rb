module Buildizer
  module Image
    class Base
      attr_reader :instructions
      attr_reader :docker

      attr_accessor :target

      def initialize(docker, **kwargs)
        @instructions = []
        @docker = docker

        instruction :FROM, base_image
      end

      def os_name
        raise
      end

      def os_package_cloud_name
        os_name
      end

      def os_package_cloud_version
        os_version
      end

      def os_version
        raise
      end

      def fpm_output_type
        raise
      end

      def fpm_extra_params
      end

      def build_dep(build_dep)
        raise
      end

      def base_image
        "buildizer/#{os_name}:#{os_version}"
      end

      def name
        target.docker_image
      end

      def instruction(instruction, cmd)
        instructions << [instruction.to_s.upcase, cmd].join(' ')
      end

      def native_build_instructions(builder, target)
        raise
      end

      def patch_build_instructions(builder, target)
        raise
      end
    end # Base
  end # Image
end # Buildizer
