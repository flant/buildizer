module Buildizer
  module Refine
    refine String do
      def underscore
        self.gsub(/(.)([A-Z])/,'\1_\2').downcase
      end
    end
  end # Refine

  using Refine
end # Buildizer
