module Buildizer
  module Target
    class Patch < Base
      attr_reader :patch

      def initialize(builder, image, patch: [], **kwargs)
        super(builder, image, **kwargs)

        @patch = patch
      end
    end # Patch
  end # Target
end # Buildizer
