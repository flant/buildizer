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
          params[:fpm_script] = Array(buildizer.buildizer_conf['fpm_script'])
          params[:fpm_config_files] = buildizer.buildizer_conf['fpm_config_files'].to_h
          params[:fpm_files] = buildizer.buildizer_conf['fpm_files'].to_h
          params[:fpm_conflicts] = Array(buildizer.buildizer_conf['fpm_conflicts'])
          params[:fpm_replaces] = Array(buildizer.buildizer_conf['fpm_replaces'])
          params[:fpm_provides] = Array(buildizer.buildizer_conf['fpm_provides'])
          params[:fpm_depends] = Array(buildizer.buildizer_conf['fpm_depends'])
          params[:fpm_description] = buildizer.buildizer_conf['fpm_description']
          params[:fpm_url] = buildizer.buildizer_conf['fpm_url']
        end
      end

      def do_merge_params(into, params)
        super.tap do |res|
          res[:fpm_script] = into[:fpm_script] + Array(params['fpm_script'])
          res[:fpm_config_files] = into[:fpm_config_files].merge(params['fpm_config_files'].to_h)
          res[:fpm_files] = into[:fpm_files].merge(params['fpm_files'].to_h)
          res[:fpm_conflicts] = (into[:fpm_conflicts] + Array(params['fpm_conflicts'])).uniq
          res[:fpm_replaces] = (into[:fpm_replaces] + Array(params['fpm_replaces'])).uniq
          res[:fpm_provides] = (into[:fpm_provides] + Array(params['fpm_provides'])).uniq
          res[:fpm_depends] = (into[:fpm_depends] + Array(params['fpm_depends'])).uniq
          res[:fpm_description] = params['fpm_description'] || into[:fpm_description]
          res[:fpm_url] = params['fpm_url'] || into[:fpm_url]
        end
      end

      def check_params!(params)
        super
        if [:fpm_files, :fpm_config_files].all? {|param| params[param].empty?}
          raise Error, error: :input_error,
                       message: ["either of fpm_files or fpm_config_files ",
                                 "required in #{build_type} build_type"].join
        end
        _required_params! :package_version, params
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
          desc[:file].write! ["#!/bin/bash", *desc[:cmd], nil].join("\n")
          desc[:file].chmod 0755
        end

        version, release = target.package_version.split('-')

        ["fpm -s dir",
         "--force",
         "-p #{docker.container_build_path}",
         "-t #{target.os.fpm_output_type}",
         "-n #{target.package_name}",
         "--version=#{version}",
         "--iteration=#{release}",
         *fpm_script.values.map {|desc| "#{desc[:fpm_option]}=#{desc[:container_file]}"},
         *Array(target.os.fpm_extra_params),
         (target.maintainer ? "--maintainer=\"#{target.maintainer}\"" : nil),
         (target.fpm_description ? "--description=\"#{target.fpm_description}\"" : nil),
         (target.fpm_url ? "--url=\"#{target.fpm_url}\"" : nil),
         *target.fpm_conflicts.map{|pkg| "--conflicts=#{pkg}"},
         *target.fpm_replaces.map{|pkg| "--replaces=#{pkg}"},
         *target.fpm_provides.map{|pkg| "--provides=#{pkg}"},
         *target.fpm_depends.map{|pkg| "--depends=#{pkg}"},
         *target.fpm_config_files_expand.keys.map {|p| "--config-files=#{p}"},
         *target.fpm_files_expand.merge(target.fpm_config_files_expand).map {|p1, p2| "#{p2}=#{p1}"},
        ].compact.join(' ')
      end
    end # Fpm
  end # Builder
end # Buildizer
