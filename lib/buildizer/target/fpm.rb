module Buildizer
  module Target
    class Fpm < Base
      include PackageNameMod

      def initialize(builder, os,
                     fpm_script: [], fpm_config_files: {}, fpm_files: {},
                     fpm_conflicts: [], fpm_replaces: {}, fpm_provides: [],
                     fpm_depends: [], fpm_description: nil, fpm_url: nil, **kwargs, &blk)
        super(builder, os, **kwargs) do
          params[:fpm_script] = fpm_script
          params[:fpm_config_files] = fpm_config_files
          params[:fpm_files] = fpm_files
          params[:fpm_conflicts] = fpm_conflicts
          params[:fpm_replaces] = fpm_replaces
          params[:fpm_provides] = fpm_provides
          params[:fpm_depends] = fpm_depends
          params[:fpm_description] = fpm_description
          params[:fpm_url] = fpm_url

          yield if block_given?
        end
      end

      def image_work_path
        builder.work_path.join('fpm').join(package_name).join(package_version).join(name)
      end

      def package_version_tag_param_name
        :package_version
      end

      def fpm_config_files_expand
        _expand_files_directive fpm_config_files
      end

      def fpm_files_expand
        _expand_files_directive fpm_files
      end

      def _expand_files_directive(files)
        files.reduce({}) do |res, (dst, src)|
          if src.is_a? Array
            res.merge src.map {|src_file| [File.join(dst, src_file), src_file]}.to_h
          elsif src.nil?
            res.merge dst => File.basename(dst)
          else
            res.merge dst => src
          end
        end
      end
    end # Fpm
  end # Target
end # Buildizer
