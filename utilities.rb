# encoding: utf-8

def str_arr_encoding_convert(arr, to)
  result = []
  arr.each do |item|
    unless item.nil?
      if item.respond_to?(:encode)
        result << item.encode(to, {invalid: :replace, undef: :replace})
      else
        result << item
      end
    end
  end
  result
end



# for test purpose
def test_arr(arr)
  arr.each { |item| p item.to_s }
end

def test_hash(hash)
  hash.each { |key, value| p "#{key}: #{value}" }
end

def test_pt(pt)
  pt.each { |key, value| p "#{key}: #{value.check_list_num}" }
end