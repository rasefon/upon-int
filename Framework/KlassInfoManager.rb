# encoding: utf-8
require "Framework/generator"
require "Framework/sql_stmt_manager"
require "config/DBUtilities"
require "config/GlobalSettings"

TABLE_NAME = "klass_names"

class KlassName < ActiveRecord::Base
  #self.primary_key = "file_name"

  def self.get_table_size
    sql = "select * from #{TABLE_NAME}"
    result = self.find_by_sql(sql)
    result.size
  end
end

#SQLRunner.generate_table(DBUtilities.db, TABLE_NAME, %w(file_name klass_name))

class KlassNameManager
  @cache = {}

  def self.get_klass_name(file_name)
    fn = file_name.encode($em.internal)

    return @cache[file_name] if @cache.has_key?(fn)

    item = KlassName.find_by_file_name(fn)
    if item.nil?
      kn = "Klass#{KlassName.get_table_size.to_s}"
      kn_new = KlassName.new
      kn_new.file_name = file_name
      kn_new.klass_name = kn
      kn_new.save
      item = kn
    else
      item = item.klass_name
    end
    @cache[file_name] = item
  end

  def self.has_klass_name?(file_name)
    fn = file_name.encode($em.internal)
    @cache.has_key?(fn) || !KlassName.find_by_file_name(fn).nil?
  end

  #def self.close
  #  @db.close if @db
  #end
  #
  #def self.drop
  #  @db.drop_table(TABLE_NAME)
  #end
end

class TableColumns
  @columns = ('a1'..'z9').to_a
  class << self
    def [] (num)
      @columns[num]
    end

    def columns
      @columns
    end
  end
end

class TableNameManager
  def self.get_table_name(class_name)
    "#{class_name.downcase}s"
  end
end