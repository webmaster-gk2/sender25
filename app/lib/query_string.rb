# frozen_string_literal: true

class QueryString

  def initialize(string)
    @string = string.strip + " "
  end

  def [](value)
    hash[value.to_s]
  end

  delegate :empty?, to: :hash

  def hash
    @hash ||= @string.scan(/([a-z]+):\s*(?:(\d{2,4}-\d{2}-\d{2}\s\d{2}:\d{2})|"(.*?)"|(.*?))(\s|\z)/).each_with_object({}) do |(key, date, string_with_spaces, value), hash|
      if date
        actual_value = date
      elsif string_with_spaces
        actual_value = string_with_spaces
      elsif value == "[blank]"
        actual_value = nil
      else
        actual_value = value
      end

      if hash.keys.include?(key.to_s)
        hash[key.to_s] = [hash[key.to_s]].flatten
        hash[key.to_s] << actual_value
      else
        hash[key.to_s] = actual_value
      end
    end
  end

end
