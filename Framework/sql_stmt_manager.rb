# encoding: utf-8

require "config/DBUtilities"

class SQLRunner
  def self.generate_table(db, table_name, args)
    arg_stmt = ""
    args.each { |e| arg_stmt << "#{e} TEXT," }
    arg_stmt = arg_stmt.chop
    primary_key_stmt = ""
    if "mysql2" == DBUtilities["adapter"]
      primary_key_stmt = " id int(11) DEFAULT NULL auto_increment PRIMARY KEY,"
    end

    sql = "CREATE TABLE IF NOT EXISTS #{table_name} (#{primary_key_stmt}#{arg_stmt})"
    exec(db, sql)
  end

  def self.drop_table(db, table_name)
    exec(db, "DROP TABLE IF EXISTS #{table_name}")
  end

  private

  def self.exec(db, sql)
    if "sqlite3" == DBUtilities["adapter"]
      db.execute(sql)
    else
      db.query(sql)
    end
  end
end