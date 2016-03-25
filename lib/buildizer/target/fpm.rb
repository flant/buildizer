module Buildizer
  module Target
    class Fpm < Base
      attr_reader :fpm_script
      attr_reader :fpm_config_files
      attr_reader :fpm_files
      attr_reader :fpm_conflicts

      def initialize(builder, image,
                     fpm_script: [], fpm_config_files: {},
                     fpm_files: {}, fpm_conflicts: [], **kwargs)
        super(builder, image, **kwargs)

        @fpm_script = fpm_script
        @fpm_config_files = fpm_config_files
        @fpm_files = fpm_files
        @fpm_conflicts = fpm_conflicts
      end
    end # Fpm
  end # Target
end # Buildizer
