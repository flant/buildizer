module Buildizer
  class Packager
    module CiMod
      def ci_name
        @ci_name ||= begin
          case git_remote_url.to_s
          when /github/
            'travis'
          when /gitlab/
            'gitlab-ci'
          else
            raise Error, error: :input_error, message: "unable to determine ci to use"
          end
        end
      end

      def ci
        @ci ||= begin
          klass = {'travis' => Ci::Travis,
                   'gitlab-ci' => Ci::GitlabCi}[ci_name.to_s.downcase]
          raise Error, message: "unknown ci '#{ci_name}'" unless klass
          klass.new(self)
        end
      end
    end # CiMod
  end # Packager
end # Buildizer
