module Buildizer
  module Builder
    class Fpm < Base
      FPM_SCRIPT_EVENTS = [:before, :after].map {|at|
                            [:install, :upgrade, :remove].map {|event|
                              "#{at}_#{event}"}}.flatten

      def build_type
        'fpm'
      end

      def target_klass
        Target::Fpm
      end

      def initial_target_params
        super.tap do |params|
          params[:fpm_script] = Array(packager.buildizer_conf['fpm_script'])
          params[:fpm_config_files] = packager.buildizer_conf['fpm_config_files'].to_h
          params[:fpm_files] = packager.buildizer_conf['fpm_files'].to_h
          params[:fpm_conflicts] = Array(packager.buildizer_conf['fpm_conflicts'])
        end
      end

      def cannot_redefine_package_params!(params, redefine_for: nil)
        [:package_name, :package_version].each do |param|
          raise(Error,
            error: :input_error,
            message: [
              "cannot redefine #{param}",
              redefine_for ? "for #{redefine_for}" : nil,
              "in #{build_type} build_type",
            ].compact.join(' ')
          ) if params.key? param.to_s
        end
      end

      def do_merge_params(into, params)
        super.tap do |res|
          res[:fpm_script] = into[:fpm_script] + Array(params['fpm_script'])
          res[:fpm_config_files] = into[:fpm_config_files].merge(params['fpm_config_files'].to_h)
          res[:fpm_files] = into[:fpm_files].merge(params['fpm_files'].to_h)
          res[:fpm_conflicts] = into[:fpm_conflicts] + Array(params['fpm_conflicts'])
        end
      end

      def merge_os_params(os_name, **kwargs, &blk)
        super(os_name, **kwargs) do |into, params|
          yield into, params if block_given?
          cannot_redefine_package_params!(params, redefine_for: "os '#{os_name}'")
        end
      end

      def merge_os_version_params(os_name, os_version, **kwargs, &blk)
        super(os_name, os_version, **kwargs) do |into, params|
          yield into, params if block_given?
          cannot_redefine_package_params!(params,
                                          redefine_for: "os version '#{os_name}-#{os_version}'")
        end
      end

      def merge_base_target_params(target, target_package_name, target_package_version, **kwargs, &blk)
        super(target, target_package_name, target_package_version, **kwargs) do |into, params|
          yield into, params if block_given?
          cannot_redefine_package_params!(params, redefine_for: "target '#{target}'")
        end
      end

      def check_params!(params)
        super
        if [:fpm_files, :fpm_config_files].all? {|param| params[param].empty?}
          raise Error, error: :input_error,
                       message: ["either of fpm_files or fpm_config_files ",
                                 "required in #{build_type} build_type"].join
        end
      end

      def build_instructions(target)
        fpm_script = target.fpm_script.reduce({}) do |res, spec|
          conditions = Array(spec['when'])
          raise Error, message: ["no when conditions given ",
                                 "for fpm_script of target ",
                                 "'#{target.name}'"].join unless conditions.any?

          cmd = Array(spec['do'])
          next res unless cmd.any?
          conditions.each do |_when|
            raise(
              Error,
              message: "unknown fpm_script event #{_when.inspect}"
            ) unless FPM_SCRIPT_EVENTS.include? _when
            res[_when] ||= {fpm_option: "--#{_when.split('_').join('-')}",
                            file: target.image_extra_path.join("fpm_#{_when}.sh"),
                            container_file: docker.container_extra_path.join("fpm_#{_when}.sh"),
                            cmd: []}
            res[_when][:cmd] += cmd
          end
          res
        end

        fpm_script.values.map do |desc|
          desc[:file].write ["#!/bin/bash", *desc[:cmd], nil].join("\n")
          desc[:file].chmod 0755
        end

        version, release = target.package_version.split('-')

        ["fpm -s dir",
         "--force",
         "-p #{docker.container_build_path}",
         "-t #{target.image.fpm_output_type}",
         "-n #{target.package_name}",
         "--version=#{version}",
         "--iteration=#{release}",
         *fpm_script.values.map {|desc| "#{desc[:fpm_option]}=#{desc[:container_file]}"},
         *Array(target.image.fpm_extra_params),
         *target.fpm_config_files.keys.map {|p| "--config-files=#{p}"},
         *target.fpm_files.merge(target.fpm_config_files).map {|p1, p2| "#{p2}=#{p1}"},
         *target.fpm_conflicts.map{|pkg| "--conflicts=#{pkg}"},
        ].join(' ')
      end
    end # Fpm
  end # Builder
end # Buildizer
