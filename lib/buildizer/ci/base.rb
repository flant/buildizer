module Buildizer
  module Ci
    class Base
      using Refine

      attr_reader :packager

      def initialize(packager)
        super()

        @packager = packager
      end

      def conf
        @conf ||= conf_path.load_yaml
      end

      def conf_path
        packager.package_path.join(conf_file_name)
      end

      def conf_file_name
        ".#{ci_name}.yml"
      end

      def ci_name
        self.class.ci_name
      end

      def cli
        @cli ||= Buildizer::Cli::Ci::Base.new(self)
      end

      def setup!
        raise
      end

      def git_tag
        res = _git_tag.to_s
        if res.empty? then nil else res end
      end

      def _git_tag
        raise
      end

      def buildizer_install_instructions(latest: nil)
        if latest
          ['git clone https://github.com/flant/buildizer ~/buildizer',
           'echo "export BUNDLE_GEMFILE=~/buildizer/Gemfile" | tee -a ~/.bashrc',
           'export BUNDLE_GEMFILE=~/buildizer/Gemfile',
           'gem install bundler',
           'gem install overcommit',
           'bundle install',
          ]
        else
          'gem install buildizer'
        end
      end

      class << self
        def ci_name
          raise
        end
      end # << self
    end # Base
  end # Ci
end # Buildizer
