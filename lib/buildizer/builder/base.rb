module Buildizer
  module Builder
    class Base
      attr_reader :packager
      attr_reader :build_path
      attr_reader :docker

      def initialize(packager)
        @packager = packager

        @build_path = packager.work_path.join('build').expand_path
        build_path.mkpath

        @docker = Docker.new(self,
          username: packager.docker_username,
          password: packager.docker_password,
          email: packager.docker_email,
          server: packager.docker_server,
        )
      end

      def build_type
        raise
      end

      def target_klass
        raise
      end

      def build_instructions(target)
      end

      def build_dep
      end

      def new_target(target_name)
        os_name, os_version, target_package_name, target_package_version = target_name.split('-', 4)

        image = docker.new_image(os_name, os_version)

        params = merge_os_params(image.os_name)
        params = merge_os_version_params(image.os_name, image.os_version, into: params)
        params = merge_base_target_params(target_name, target_package_name, target_package_version,
                                          into: params) if target_package_name
        check_params! params

        target_klass.new(self, image, name: target_name, **params).tap do |target|
          image.target = target
        end
      end

      def targets
        @targets ||= packager.targets.map {|target_name| new_target(target_name)}
      end

      def initial_target_params
        {}.tap do |params|
          params[:package_name] = packager.package_name
          params[:package_version] = packager.package_version
          params[:package_cloud] = packager.package_cloud
          params[:prepare] = packager.prepare
          params[:build_dep] = packager.build_dep
          params[:before_build] = packager.before_build
        end
      end

      def merge_params(into: nil, params:, &blk)
        into ||= initial_target_params
        params ||= {}
        yield into, params if block_given?
        do_merge_params into, params
      end

      def do_merge_params(into, params)
        {}.tap do |res|
          res[:package_name] = into[:package_name] || params['package_name']
          res[:package_version] = into[:package_version] || params['package_version']
          res[:package_cloud] = into[:package_cloud]
          res[:prepare] = into[:prepare] + Array(params['prepare'])
          res[:build_dep] = into[:build_dep] | Array(params['build_dep']).to_set
          res[:before_build] = into[:before_build] + Array(params['before_build'])
        end
      end

      def merge_os_params(os_name, into: nil, &blk)
        merge_params(into: into, params: packager.os_params(os_name), &blk)
      end

      def merge_os_version_params(os_name, os_version, into: nil, &blk)
        merge_params(into: into,
                     params: packager.os_params([os_name, os_version].join('-')), &blk)
      end

      def merge_base_target_params(target, target_package_name, target_package_version,
                                   into: nil, &blk)
        merge_params(into: into,
                     params: {'package_name' => target_package_name,
                              'package_version' => target_package_version}, &blk)
      end

      def check_params!(params)
        [:package_name, :package_version, :package_cloud].each do |param|
          raise(Error,
                error: :input_error,
                message: "#{param} is not defined") unless params[param] and not params[param].empty?
        end
      end

      def prepare
        return unless packager.enabled?

        docker.login!

        begin
          packager.before_prepare.each {|cmd| packager.command! cmd, desc: "Before prepare command: #{cmd}"}
          targets.each {|target| prepare_target_image(target)}
          packager.after_prepare.each {|cmd| packager.command! cmd, desc: "After prepare command: #{cmd}"}
        ensure
          docker.logout!
        end
      end

      def prepare_target_image(target)
        target.image_build_path.mkpath
        target.prepare.each {|cmd| target.image.instruction(:RUN, "bash -lec \"#{cmd}\"")}
        target.image.build_dep(Array(build_dep).to_set + target.build_dep)
        docker.build_image! target
      end

      def build
        return unless packager.enabled?
        targets.each {|target| build_target(target)}
      end

      def build_target(target)
        target.image_runtime_build_path.mkpath

        cmd = [
          "rm -rf #{docker.container_build_path.join('*')}",
          "cd /package",
          *target.before_build,
          *Array(build_instructions(target)),
        ]

        docker.run_in_image! target, cmd: cmd
      end

      def deploy
        return unless packager.enabled?
        targets.each {|target| deploy_target(target)}
      end

      def deploy_target(target)
        cmd = Dir[target.image_runtime_build_path.join("*.#{target.image.fpm_output_type}")]
                .map {|p| Pathname.new(p)}
                .map {|p| ["package_cloud yank #{target.package_cloud_path} #{p.basename}",
                           "package_cloud push #{target.package_cloud_path} #{p}",
                           p.basename]}
                .each {|yank, push, package|
                  packager.command yank, desc: ["Package cloud yank package '#{package}'",
                                                " of target '#{target.name}'"].join
                  packager.command! push, desc: ["Package cloud push package '#{package}'",
                                                 " of target '#{target.name}'"].join
                }
      end
    end # Base
  end # Builder
end # Buildizer
