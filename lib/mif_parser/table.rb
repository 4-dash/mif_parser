module MifParser
  class Table
    attr_reader :id, :tag, :rows

    def initialize(id:, tag: nil, rows: [])
      @id = id
      @tag = tag
      @rows = rows
    end

    def interpret(interpreter = Interpreter.default)
      interpreter.interpret(self)
    end
  end
end