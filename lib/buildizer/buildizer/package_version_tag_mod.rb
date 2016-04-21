module Buildizer
  class Buildizer
    module PackageVersionTagMod
      def package_version_tag_required_for_deploy?
        ENV['BUILDIZER_REQUIRE_TAG'].to_s.on?
      end

      def package_version_tag
        ci.git_tag
      end
    end # PackageVersionTagMod
  end # Buildizer
end # Buildizer
