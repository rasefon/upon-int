# encoding: utf-8
require "csv"
require "Model/product"
require "utilities"

class ProductTable < Hash
  PRODUCT_ID = 2
  PRODUCT_NAME = 3
  STANDARD = 4
  BAR_CODE = 5
  PRODUCT_DESCRIPTION = 21
  LOCATION = 28
  ONLINE_NUM = 47
  CHECK_LIST_NUM = 9
  STORAGE_NUM = 8

  def initialize(csv_src_file)
    @csv_src_file = csv_src_file
  end

  def parse
    # First check the encoding of source csv file.
    ec = ""
    File.open(@csv_src_file) do |f|
      ec = f.readline.encoding.to_s
    end
    ec = "GBK" if "GB2312" == ec

    csv_data = CSV.read(@csv_src_file, {encoding: "#{ec}:utf-8"})
    # delete first row.
    @title_arr = csv_data.delete_at(0)
    @title_arr = [@title_arr[BAR_CODE], @title_arr[STORAGE_NUM], @title_arr[CHECK_LIST_NUM]]

    csv_data.each do |item|
      next if item.empty?
      product = Product.new(item[PRODUCT_ID], item[PRODUCT_NAME], item[STANDARD], item[BAR_CODE], item[PRODUCT_DESCRIPTION], item[LOCATION],
                        item[ONLINE_NUM], item[CHECK_LIST_NUM], item[STORAGE_NUM])
      self[item[BAR_CODE]] = product
    end
    self
  end

  def get_title_name(ec)
    ta = str_arr_encoding_convert(@title_arr, ec)
    ta.to_csv
  end
end

# Merge t2 into t1
def merge_product_table(t1, t2 )
  unless t1.nil? or t2.nil?
    t1.each do |key, value|
      value.check_list_num += t2[key].check_list_num if t2.has_key?(key)
    end
  end
end

# Compare dest product table to src, if there is any difference, log the result and return it.
def compare_product_table(dest_pt, src_pt)
  result = []
  dest_pt.each do |key, value|
    result << value unless src_pt.has_key?(key)
    result << value unless value.compare_to?(src_pt[key])
  end
  result
end
