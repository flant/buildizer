module Buildizer
  module Os
    class Centos7 < Centos
      def initialize(docker, **kwargs)
        super(docker, 'centos7', **kwargs)
      end
    end # Centos7
  end # Os
end # Buildizer
