module MifParser
  class Table < Element
    attr_reader :id, :rows

    def initialize(id:, tag: nil, rows: [])
      super(tag: tag)

      @id = id
      @rows = rows
    end
  end
end