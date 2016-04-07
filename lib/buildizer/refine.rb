module Buildizer
  module Refine
    refine String do
      def underscore
        self.gsub(/(.)([A-Z])/,'\1_\2').downcase
      end

      def match_glob?(glob)
        File.fnmatch? glob, self, File::FNM_EXTGLOB
      end
    end
  end # Refine
end # Buildizer
