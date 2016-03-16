module Buildizer
  module Image
    class Ubuntu1204 < Ubuntu
      def initialize(docker, **kwargs)
        super(docker, '12.04', **kwargs)
      end

      def os_codename
        'precise'
      end
    end # Ubuntu1204
  end # Image
end # Buildizer
