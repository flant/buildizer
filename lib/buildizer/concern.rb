module Buildizer
  module Concern
    def command(*args)
      Shellfold.run(*args)
    end

    def command!(*args)
      Shellfold.run(*args)
    end
  end # Concern
end # Buildizer
