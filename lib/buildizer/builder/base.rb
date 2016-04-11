module Buildizer
  module Builder
    class Base
      using Refine

      attr_reader :packager
      attr_reader :work_path
      attr_reader :docker

      def initialize(packager)
        @packager = packager

        @work_path = packager.work_path.join('builder').expand_path
        work_path.mkpath

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

      def build_dep(target)
      end

      def new_target(target_name)
        os_name, os_version, target_tag = target_name.split('/', 3)

        image = docker.new_image(os_name, os_version)

        params = initial_target_params
        packager.buildizer_conf.each do |match_key, match_params|
          match_os_name, match_os_version, match_target_tag = match_key.to_s.split('/', 3)
          if image.os_name.match_glob?(match_os_name) and
            ( match_os_version.nil? or image.os_version.match_glob?(match_os_version) ) and
              ( match_target_tag.nil? or (not target_tag.nil? and
                                          target_tag.match_glob?(match_target_tag)) )
            params = merge_params(into: params, params: match_params)
          end
        end

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
          params[:maintainer] = packager.maintainer
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
          res[:package_name] = params['package_name'] || into[:package_name]
          res[:package_version] = params['package_version'] || into[:package_version]
          res[:package_cloud] = into[:package_cloud]
          res[:prepare] = into[:prepare] + Array(params['prepare'])
          res[:build_dep] = into[:build_dep] | Array(params['build_dep']).to_set
          res[:before_build] = into[:before_build] + Array(params['before_build'])
          res[:maintainer] = params['maintainer'] || into[:maintainer]
        end
      end

      def check_params!(params)
        _required_params! :package_name, params
      end

      def _required_params!(required_params, params)
        Array(required_params).each do |param|
          unless params[param] and not params[param].to_s.empty?
            raise Error, error: :input_error, message: "#{param} is not defined"
          end
        end
      end

      def build_jobs
        File.open('/proc/cpuinfo').readlines.grep(/processor/).size
      end

      def verify
        targets.tap do |res|
          unless res.any?
            raise Error, error: :input_error, message: "target is not defined"
          end
        end
      end

      def prepare
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
        target.prepare.each {|cmd| target.image.instruction(:RUN, "bash -lec \"#{cmd}\"")}
        target.image.build_dep(Array(build_dep(target)).to_set + target.build_dep)
        docker.build_image! target
      end

      def build
        targets.each {|target| build_target(target)}
      end

      def prepare_package_source_instructions(target)
        ["cp -r #{docker.container_package_mount_path} #{target.container_package_path}",
         "rm -rf #{target.container_package_path.join('.git')}",
         "cd #{target.container_package_path.dirname}",
         ["tar -zcvf #{target.container_package_archive_path} ",
          "#{target.container_package_path.basename}"].join,
         "ln -fs #{target.container_package_path} #{docker.container_package_path}",
         "ln -fs #{target.container_package_archive_path} #{docker.container_package_archive_path}"]
      end

      def build_target(target)
        cmd = [
          *Array(prepare_package_source_instructions(target)),
          "rm -rf #{docker.container_build_path.join('*')}",
          "cd #{docker.container_package_path}",
          *target.before_build,
          *Array(build_instructions(target)),
        ]

        docker.run_in_image!(target: target, cmd: cmd,
                             desc: "Run build in docker image '#{target.image.name}'")
      end

      def deploy
        if packager.package_version_tag_required_for_deploy? and
           not packager.package_version_tag
          puts "package_version_tag (env TRAVIS_TAG or CI_BUILD_TAG) required: ignoring deploy"
          return
        elsif packager.package_cloud.empty?
          warn "No package cloud settings " +
               "(PACKAGECLOUD, PACKAGECLOUD_TOKEN, PACKAGECLOUD_TOKEN_<ORG>) [WARN]"
          return
        end

        packager.package_cloud_org.each do |org, token|
          unless token
            warn "No packagecloud token defined for org '#{org}' " +
                 "(PACKAGECLOUD_TOKEN or PACKAGECLOUD_TOKEN_#{org.upcase}) [WARN]"
          end
        end

        targets.map do |target|
          target.tap do
            if packager.package_version_tag_required_for_deploy? and
               packager.package_version_tag != target.package_version_tag
              raise(Error, error: :logical_error,
                           message: "#{target.package_version_tag_param_name} and "+
                                    "package_version_tag (env TRAVIS_TAG or CI_BUILD_TAG) " +
                                    "should be the same for target '#{target.name}'")
            end
          end
        end.each {|target| deploy_target(target)}
      end

      def deploy_target(target)
        cmd = Dir[target.image_build_path.join("*.#{target.image.fpm_output_type}")]
                .map {|p| Pathname.new(p)}.map {|package_path|
                  package = package_path.basename
                  target.package_cloud.map do |desc|
                    desc.merge(
                      package: package,
                      yank: "package_cloud yank #{desc[:package_path]} #{package}",
                      push: "package_cloud push #{desc[:package_path]} #{package_path}",
                    )
                  end
                }.flatten.each {|desc|
                  packager.command desc[:yank],
                    desc: ["Package cloud yank package '#{desc[:package]}'",
                           " of target '#{target.name}'"].join,
                    environment: {'PACKAGECLOUD_TOKEN' => desc[:token]}

                  packager.command desc[:push],
                    desc: ["Package cloud push package '#{desc[:package]}'",
                           " of target '#{target.name}'"].join,
                    environment: {'PACKAGECLOUD_TOKEN' =>desc[:token]}
                }
      end
    end # Base
  end # Builder
end # Buildizer
