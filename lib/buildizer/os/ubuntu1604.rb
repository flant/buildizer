module Buildizer
  module Os
    class Ubuntu1604 < Ubuntu
      def initialize(docker, **kwargs)
        super(docker, '16.04', **kwargs)
      end

      def codename
        'xenial'
      end
    end # Ubuntu1604
  end # Os
end # Buildizer
