module Buildizer
  module Ci
    class GitlabCi < Base
      def _git_tag
        ENV['CI_BUILD_TAG']
      end

      class << self
        def ci_name
          'gitlab-ci'
        end
      end # << self
    end # GitlabCi
  end # Ci
end # Buildizer
