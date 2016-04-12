module Buildizer
  module Cli
    class Main < Base
      include OptionsMod

      desc "setup", "Setup buildizer settings and hooks"
      subcommand "setup", Setup

      desc "init", "Initialize settings (.travis.yml, .buildizer.yml, git pre-commit hook)"
      shared_options
      method_option :latest,
        type: :boolean,
        desc: "use buildizer github master branch"
      def init
        self.class.construct_packager(options).init!
      end

      desc "update", "Regenerate .travis.yml"
      shared_options
      def update
        self.class.construct_packager(options).update!
      end

      desc "deinit", "Deinitialize settings (.buildizer.yml, git pre-commit hook)"
      shared_options
      def deinit
        self.class.construct_packager(options).deinit!
      end

      desc "prepare", "Prepare images for building packages"
      shared_options
      def prepare
        self.class.construct_packager(options).prepare!
      end

      desc "build", "Build packages"
      shared_options
      def build
        self.class.construct_packager(options).build!
      end

      desc "deploy", "Deploy packages"
      shared_options
      def deploy
        self.class.construct_packager(options).deploy!
      end

      desc "verify", "Verify targets params"
      shared_options
      def verify
        self.class.construct_packager(options).verify!
      end
    end # Main
  end # Cli
end # Buildizer
