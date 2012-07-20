# encoding: utf-8
$LOAD_PATH.unshift(File.dirname(__FILE__)) unless $LOAD_PATH.include?(File.dirname(__FILE__))

require "Controller/product_data_parser"
require "utilities"

# For testing
src_fn = "库存.csv"
result_fn = "result.csv"

# get all the file from dest folder
dest_fn = "dest"
if Dir.exist?(dest_fn)
  pt1 = nil
  Dir.chdir(dest_fn) do
    fn_arr = Dir.glob("*.csv")

    if fn_arr.length == 0
      STDERR << "dest folder is empty!"
    else
      pt1 = ProductTable.new(fn_arr.delete_at(0)).parse
      fn_arr.each do |fn|
        tmp_pt = ProductTable.new(fn).parse
        merge_product_table(pt1, tmp_pt)
      end
    end
  end

  if pt1
    src_pt = ProductTable.new(src_fn).parse

    # Compare to src csv file
    result_arr = compare_product_table(pt1, src_pt)
    result_f = File.open(result_fn, "w:gbk")

    # add title
    result_f << "#{pt1.get_title_name("gbk")}"
    # add content
    result_arr.each do |product|
      result_f << product.get_diff("gbk")
    end
    result_f.close
  end
else
  STDERR << "dest folder doesn't existed!"
end
