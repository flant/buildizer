module Buildizer
  module Target
    class Fpm < Base
      attr_reader :fpm_script
      attr_reader :fpm_config_files
      attr_reader :fpm_files

      def initialize(builder, image, fpm_script: [], fpm_config_files: {}, fpm_files: {}, **kwargs)
        super(builder, image, **kwargs)

        @fpm_script = fpm_script
        @fpm_config_files = fpm_config_files
        @fpm_files = fpm_files
      end
    end # Fpm
  end # Target
end # Buildizer
