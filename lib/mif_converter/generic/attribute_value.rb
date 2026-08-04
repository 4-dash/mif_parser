module MifConverter
  module Generic
    module AttributeValue
      module StyleType # can have different Types ie distance
        H1   = :h1
        H2   = :h2
        BODY = :body

        ALL = [H1, H2, BODY].freeze
      end
    end
  end
end