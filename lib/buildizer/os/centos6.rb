module Buildizer
  module Os
    class Centos6 < Centos
      def initialize(docker, **kwargs)
        super(docker, 'centos6', **kwargs)
      end
    end # Centos6
  end # Os
end # Buildizer
