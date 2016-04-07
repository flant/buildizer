module Buildizer
  module Target
    module PackageNameMod
      def package_upstream_version
        package_version.split('-')[0]
      end

      def package_release
        package_version.split('-')[1]
      end

      def container_package_name
        "#{package_name}-#{package_upstream_version}"
      end
    end # PackageNameMod
  end # Target
end # Buildizer
