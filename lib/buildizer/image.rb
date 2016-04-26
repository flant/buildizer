module Buildizer
  class Image
    attr_reader :instructions
    attr_reader :name
    attr_reader :from

    def initialize(name, from: nil)
      @name = name
      @from = from
      @instructions = []

      instruction :FROM, from if from
    end

    def instruction(instruction, cmd)
      instructions << [instruction.to_s.upcase, cmd].join(' ')
    end
  end # Image
end # Buildizer
