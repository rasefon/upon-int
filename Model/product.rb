# encoding: utf-8

require "utilities"

class Product
  def initialize(product_id, product_name, standard, bar_code, product_description, location, online_num,
      check_list_num, storage_num)
    @product_id = product_id
    @product_name = product_name
    @standard = standard
    @bar_code = bar_code
    @product_description = product_description
    @location = location
    @online_num = online_num
    @check_list_num = check_list_num.to_i
    @storage_num = storage_num.to_i
  end

  attr_accessor :product_id
  attr_accessor :product_name
  attr_accessor :standard
  attr_accessor :bar_code
  attr_accessor :product_description
  attr_accessor :location
  attr_accessor :online_num
  attr_accessor :check_list_num
  attr_accessor :storage_num

  def compare_to?(product)
    return false unless (product.respond_to?(:product_id) or product.respond_to?(:product_name) or product.respond_to?(:standard) or
        product.respond_to?(:bar_code) or product.respond_to?(:product_description) or product.respond_to?(:location) or
        product.respond_to?(:online_num) or product.respond_to?(:check_list_num) or product.respond_to?(:storage_num))

    return true if (@product_id == product.product_id and @product_description == product.product_description and
        @standard == product.standard and @bar_code == product.bar_code and @product_name == product.product_name and
        @location == product.location and @online_num == product.online_num and @check_list_num == product.check_list_num and
        @storage_num == product.storage_num)

    false
  end

  def get_diff(ec)
    tmp_arr = [@bar_code, @storage_num, @check_list_num]
    tmp_arr = str_arr_encoding_convert(tmp_arr, ec)
    tmp_arr.to_csv
  end
end
