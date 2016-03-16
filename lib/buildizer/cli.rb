module Buildizer
  class Cli < ::Thor
    desc "init", "Initialize settings (.travis.yml, .buildizer.yml, git pre-commit hook)"
    method_option :latest,
      type: :boolean,
      desc: "use buildizer github master branch"
    def init
      Packager.new(options: options).init!
    end

    desc "update", "Regenerate .travis.yml"
    def update
      Packager.new(options: options).update!
    end

    desc "deinit", "Deinitialize settings (.buildizer.yml, git pre-commit hook)"
    def deinit
      Packager.new(options: options).deinit!
    end

    desc "prepare", "Prepare images for building packages"
    def prepare
      Packager.new(options: options).prepare!
    end

    desc "build", "Build packages"
    def build
      Packager.new(options: options).build!
    end

    desc "deploy", "Deploy packages"
    def deploy
      Packager.new(options: options).deploy!
    end
  end # Cli
end # Buildizer
