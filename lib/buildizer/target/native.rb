module Buildizer
  module Target
    class Native < Base
      include PackageNameMod

      def image_work_path
        builder.work_path.join('native').join(package_name).join(package_version).join(name)
      end

      def package_version_tag_param_name
        :package_version
      end
    end # Native
  end # Target
end # Buildizer
