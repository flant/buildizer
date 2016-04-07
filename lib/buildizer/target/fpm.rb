module Buildizer
  module Target
    class Fpm < Base
      include PackageNameMod

      attr_reader :fpm_script
      attr_reader :fpm_config_files
      attr_reader :fpm_files
      attr_reader :fpm_conflicts
      attr_reader :fpm_replaces
      attr_reader :fpm_provides
      attr_reader :fpm_depends
      attr_reader :fpm_description
      attr_reader :fpm_maintainer
      attr_reader :fpm_url

      def initialize(builder, image,
                     fpm_script: [], fpm_config_files: {}, fpm_files: {},
                     fpm_conflicts: [], fpm_replaces: {}, fpm_provides: [],
                     fpm_depends: [], fpm_description: nil, fpm_maintainer: nil,
                     fpm_url: nil, **kwargs, &blk)
        super(builder, image, **kwargs) do
          @fpm_script = fpm_script
          @fpm_config_files = fpm_config_files
          @fpm_files = fpm_files
          @fpm_conflicts = fpm_conflicts
          @fpm_replaces = fpm_replaces
          @fpm_provides = fpm_provides
          @fpm_depends = fpm_depends
          @fpm_description = fpm_description
          @fpm_maintainer = fpm_maintainer
          @fpm_url = fpm_url

          yield if block_given?
        end
      end

      def image_work_path
        builder.work_path.join('fpm').join(package_name).join(package_version).join(name)
      end

      def package_version_tag_param_name
        :package_version
      end
    end # Fpm
  end # Target
end # Buildizer
