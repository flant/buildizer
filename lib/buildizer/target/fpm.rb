module Buildizer
  module Target
    class Fpm < Base
      attr_reader :fpm_script
      attr_reader :fpm_config_files
      attr_reader :fpm_files
      attr_reader :fpm_conflicts
      attr_reader :fpm_depends

      def initialize(builder, image,
                     fpm_script: [], fpm_config_files: {},
                     fpm_files: {}, fpm_conflicts: [],
                     fpm_depends: [], **kwargs)
        super(builder, image, **kwargs)

        @fpm_script = fpm_script
        @fpm_config_files = fpm_config_files
        @fpm_files = fpm_files
        @fpm_conflicts = fpm_conflicts
        @fpm_depends = fpm_depends
      end
    end # Fpm
  end # Target
end # Buildizer
