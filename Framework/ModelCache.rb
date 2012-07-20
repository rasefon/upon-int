# encoding: utf-8
require "csv"
require "Framework/KlassInfoManager"
require "config/GlobalSettings"


class ModelCache < Array
  def initialize (src_file_name)
    klass_name = KlassNameManager.get_klass_name(src_file_name)
    table_name = TableNameManager.get_table_name(klass_name)
    if Object.const_defined?(klass_name.to_sym)
      @klass = Object.const_get(klass_name.to_sym)
    else
      puts "Can't get model for file:#{src_file_name} because it is undefined now!"
      return nil
    end

    unless @klass.table_exists?
      puts "Table:#{table_name} doesn't exist!"
    end
    @cache_with_klass_info = @klass.find_by_sql("SELECT * FROM #{table_name}")
    @cache_with_klass_info.each { |item| self << item.attributes }
  end
end

class TempTableCache < Array
  attr_accessor :titles

  # Assume that the source file is csv format.
  def initialize (src_file_name)
    if src_file_name.nil?
      return []
    end

    unless File.exist?(src_file_name)
      puts "File:#{Dir.pwd}/#{src_file_name} doesn't exist!"
      return []
    end
    @src_data = CSV.read(src_file_name, {encoding: "#{$em.external}:#{$em.internal}"})
    # parse table columns
    title_arr = @src_data.delete_at(0)
    @titles = Hash.new
    title_arr.each_index { |i| @titles[TableColumns[i]] = title_arr[i]}

    @src_data.each do |row|
      temp_hash = Hash.new
      row.each_index { |i| temp_hash[TableColumns[i]] = row[i] }
      self << temp_hash
    end
    self
  end

  def output_to_file(path)
    output_file = File.new(path, "w:#{$em.external}")
    temp_str = ""
    @titles.each_key { |k| temp_str << "#{@titles[k]}," }
    temp_str = temp_str.chop
    temp_str << "\n"
    output_file << temp_str

    self.each do |h|
      temp_str = ""
      @titles.each_key { |k| temp_str << "#{h[k]}," }
      temp_str = temp_str.chop
      temp_str << "\n"
      output_file << temp_str
    end

    output_file.close
  end

  private_class_method :new

  def self.create_from_file (src_file_name)
    new(src_file_name)
  end

  def self.create
    new(nil)
  end
end


