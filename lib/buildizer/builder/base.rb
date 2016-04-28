module Buildizer
  module Builder
    class Base
      attr_reader :buildizer
      attr_reader :work_path
      attr_reader :docker

      def initialize(buildizer)
        @buildizer = buildizer
        @work_path = buildizer.work_path.join('builder').expand_path
        @docker = Docker.new(self, cache: buildizer.docker_cache)
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

        os = docker.new_os(os_name, os_version)

        params = initial_target_params
        buildizer.buildizer_conf.each do |match_key, match_params|
          match_os_name, match_os_version, match_target_tag = match_key.to_s.split('/', 3)
          if os.name.match_glob?(match_os_name) and
            ( match_os_version.nil? or os.version.match_glob?(match_os_version) ) and
              ( match_target_tag.nil? or (not target_tag.nil? and
                                          target_tag.match_glob?(match_target_tag)) )
            params = merge_params(into: params, params: match_params)
          end
        end

        check_params! params

        target_klass.new(self, os, name: target_name, **params)
      end

      def target_names
        @target_names ||= begin
          targets = Array(buildizer.buildizer_conf['target'])
          restrict_targets = ENV['BUILDIZER_TARGET']
          restrict_targets = restrict_targets.split(',').map(&:strip) if restrict_targets
          targets = targets & restrict_targets if restrict_targets
          targets
        end
      end

      def targets
        @targets ||= target_names.map {|name| new_target(name)}
      end

      def initial_target_params
        {}.tap do |params|
          params[:package_name] = buildizer.buildizer_conf['package_name']
          params[:package_version] = buildizer.buildizer_conf['package_version']
          params[:package_cloud] = buildizer.package_cloud
          params[:prepare] = Array(buildizer.buildizer_conf['prepare'])
          params[:build_dep] = Array(buildizer.buildizer_conf['build_dep']).to_set
          params[:before_build] = Array(buildizer.buildizer_conf['before_build'])
          params[:maintainer] = buildizer.buildizer_conf['maintainer']

          params[:test_options] = Hash(buildizer.buildizer_conf['test_options'])
          params[:test_env] = buildizer.buildizer_conf['test_env'].to_h
          params[:before_test] = Array(buildizer.buildizer_conf['before_test'])
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

          res[:test_options] = into[:test_options].merge params['test_options'].to_h
          res[:test_env] = into[:test_env].merge(params['test_env'].to_h)
          res[:before_test] = into[:before_test] + Array(params['before_test'])
        end
      end

      def check_params!(params)
        _required_params! :package_name, params
      end

      def _required_params!(required_params, params)
        Array(required_params).each do |param|
          unless params[param] and not params[param].to_s.empty?
            raise Error, error: :input_error, message: "Buildizer #{param} is not defined"
          end
        end
      end

      def build_jobs
        File.open('/proc/cpuinfo').readlines.grep(/processor/).size
      end

      def verify
        targets.tap do |res|
          unless res.any?
            raise Error, error: :input_error, message: "Buildizer target is not defined"
          end
        end
      end

      def prepare
        docker.with_cache do
          Array(buildizer.buildizer_conf['before_prepare'])
            .each {|cmd| buildizer.command! cmd, desc: "Before prepare command: #{cmd}"}

          targets.each {|target| prepare_target_build_image(target)}

          Array(buildizer.buildizer_conf['after_prepare'])
            .each {|cmd| buildizer.command! cmd, desc: "After prepare command: #{cmd}"}
        end # with_cache
      end

      def prepare_target_build_image(target)
        target.prepare.each {|cmd| target.build_image.instruction(:RUN, "bash -lec \"#{cmd}\"")}
        target.os.build_dep(target.build_image, Array(build_dep(target)).to_set + target.build_dep)
        docker.make_build_image target
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

        docker.run_in_image! image: target.build_image,
                             cmd: cmd,
                             desc: "Run build in docker image '#{target.build_image.name}'"
      end

      def test
        failures = targets
          .map {|target| [target, Array(test_target(target))]}
          .reduce([]) {|res, (target, results)|
            res.push *results.map {|res|
              {target: target,
               result: res}
            }
          }
          .select {|test| test[:result].net_status_error?}

        if failures.any?
          puts
          puts "Failures:"
          failures.each do |failure|
            puts "* #{failure[:target].name} env=#{failure[:result][:data][:env]}"
            puts failure[:result][:message]
            puts
          end

          raise Error, message: "test failed"
        end
      end

      def test_target(target)
        return unless target.test_path.exist?

        target
          .test_env
          .map {|env| test_target_env(target, env)}
      end

      def install_bats_instructions(target)
        [*Array(target.os.install_git_instructions(target)),
         "cd /tmp",
         "git clone https://github.com/sstephenson/bats.git",
         "cd bats",
         "./install.sh /usr/local"]
      end

      def test_target_env(target, env)
        #TODO: privileged

        container_name = SecureRandom.uuid
        docker.with_container(
          name: container_name,
          image: target.test_image,
          env: env.merge(TERM: ENV['TERM']),
          desc: "Run test container '#{container_name}' " +
                "target='#{target.name}' env=#{env}"
        ) do |container|
          prepare_cmd = [*Array(prepare_package_source_instructions(target)),
                         *Array(install_bats_instructions(target)),
                         "cd #{docker.container_package_path}",
                         *target.before_test]

          docker.run_in_container! container: container,
                                   cmd: prepare_cmd,
                                   desc: "Run before_test stage in test container '#{container}'"

          res = docker.run_in_container container: container,
                                        cmd: "bats --pretty #{target.container_test_path}",
                                        desc: "Run test stage in test container '#{container}'",
                                        cmd_opts: {live_log: false, log_failure: false}

          {}.tap do |ret|
            ret[:data] = {env: env}
            unless res.status.success?
              ret[:error] = :error
              ret[:message] = res.stdout + res.stderr
            end
          end
        end # with_container
      end

      def deploy
        if buildizer.package_version_tag_required_for_deploy? and
           not buildizer.package_version_tag
          puts "package_version_tag (env TRAVIS_TAG or CI_BUILD_TAG) required: ignoring deploy"
          return
        elsif buildizer.package_cloud.empty?
          buildizer.warn "No package cloud settings " +
                         "(PACKAGECLOUD, PACKAGECLOUD_TOKEN, PACKAGECLOUD_TOKEN_<ORG>)"
          return
        end

        buildizer.package_cloud_org.each do |org, token|
          unless token
            buildizer.warn "No package cloud token defined for org '#{org}' " +
                           "(PACKAGECLOUD_TOKEN or PACKAGECLOUD_TOKEN_#{org.upcase})"
          end
        end

        targets.map do |target|
          target.tap do
            if buildizer.package_version_tag_required_for_deploy? and
               buildizer.package_version_tag != target.package_version_tag
              raise(Error, error: :logical_error,
                           message: "#{target.package_version_tag_param_name} and "+
                                    "package_version_tag (env TRAVIS_TAG or CI_BUILD_TAG) " +
                                    "should be the same for target '#{target.name}'")
            end
          end
        end.each {|target| deploy_target(target)}
      end

      def deploy_target(target)
        cmd = Dir[target.image_build_path.join("*.#{target.os.fpm_output_type}")]
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
                  buildizer.command desc[:yank],
                    desc: ["Package cloud yank package '#{desc[:package]}'",
                           " of target '#{target.name}'"].join,
                    environment: {'PACKAGECLOUD_TOKEN' => desc[:token]}

                  buildizer.command desc[:push],
                    desc: ["Package cloud push package '#{desc[:package]}'",
                           " of target '#{target.name}'"].join,
                    environment: {'PACKAGECLOUD_TOKEN' =>desc[:token]}
                }
      end
    end # Base
  end # Builder
end # Buildizer
