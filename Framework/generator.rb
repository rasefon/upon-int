# encoding: utf-8
require "active_record"
require "csv"
#require "mysql2"
require 'sqlite3'
require "config/DBUtilities"
require "config/GlobalSettings"
require "Framework/EncodeManager"
require "Framework/KlassInfoManager"
require "Framework/sql_stmt_manager"

def generate_model(klass_name)
  stmt = <<MODEL_DEF
        class #{klass_name} < ActiveRecord::Base
          self.table_name = \"#{TableNameManager.get_table_name(klass_name)}\"
        end
MODEL_DEF
  Kernel.eval(stmt)
end

def generate_class(klass_name)
  stmt = <<CLASS_DEF
  class #{klass_name}
  end
CLASS_DEF
  Kernel.eval(stmt)
end

module Generator
  class ModelTableGen

    def self.gen(src_file_name)
      klass_name = KlassNameManager.get_klass_name(src_file_name)
      table_name = TableNameManager.get_table_name(klass_name)
      # generate model
      generate_model(klass_name)
      klass = Object.const_get(klass_name.to_sym)

      unless klass.table_exists?
        # Import csv file.
        csv_data = CSV.read(src_file_name, {encoding: "#{$em.external}:#{$em.internal}"})
        # parse table columns
        args = []
        csv_data.delete_at(0).each_index { |i| args << "#{TableColumns[i]}" }

        # generate table.
        SQLRunner.generate_table(DBUtilities.db, table_name, args)

        #DBUtilities.model_table_connection

        # Import data
        klass.transaction do
          csv_data.each do |row|
            next if row.empty?
            obj = klass.new
            row.each_index do |i|
              obj.send("#{TableColumns[i]}=".to_sym, row[i])
            end
            obj.save
          end
        end
      end
    end

    #def self.update_table(src_file_name, key_index)
    #  klass_name = KlassNameManager.get_klass_name(src_file_name, $em)
    #  table_name = TableNameManager.get_table_name(klass_name)
    #  klass = Object.const_get(klass_name.to_sym)
    #
    #  if klass.nil?
    #    p "Can't get model #{klass_name}'"
    #    return nil
    #  end
    #
    #  unless klass.table_exists?
    #    p "Table #{table_name} doesn't exist!"
    #    return nil
    #  end
    #
    #  src_data = CSV.read(src_file_name, {encoding: "#{$em.external}:#{$em.internal}"})
    #  src_data.delete_at(0)
    #  klass.transaction do
    #    src_data.each do |row|
    #      next if row.empty?
    #      if row.size < key_index
    #        p "The key index:#{key_index} is out of range! Max value is:#{row.size}"
    #        return nil
    #      end
    #      # Primary key
    #      pk = row[key_index]
    #      src_item = klass.send("find_all_by_#{TableColumns[key_index]}", pk)
    #      if src_item.nil?
    #        src_item = klass.new
    #        row.each_index do |i|
    #          src_item.send("#{TableColumns[i]}=".to_sym, row[i])
    #        end
    #        obj.save
    #      elsif src_item.size == 1
    #        row.each_index do |i|
    #          src_item[0].send("#{TableColumns[i]}=".to_sym, row[i]) if src_item[0].send("#{TableColumns[i]}".to_sym) != row[i]
    #        end
    #        src_item[0].save
    #      else
    #        p "Can't update #{pk} because it isn't unique!"
    #        next
    #      end
    #    end
    #  end
    #end

    def self.update_table(src_file_name)
      klass_name = KlassNameManager.get_klass_name(src_file_name)
      table_name = TableNameManager.get_table_name(klass_name)
      klass = Object.const_get(klass_name.to_sym)

      if klass.nil?
        p "Can't get model #{klass_name}'"
        return nil
      end

      unless klass.table_exists?
        p "Table #{table_name} doesn't exist!"
        return nil
      end

      SQLRunner.drop_table(DBUtilities.db, table_name)
      gen(src_file_name)
    end
  end
end
