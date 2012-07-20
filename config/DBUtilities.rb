# encoding: utf-8
require "yaml"

class DBUtilities
  def self.[] (key)
    return @db_config[key] if @db_config.has_key?(key)
    nil
  end

  def self.load_config
    @db_config = YAML.load(File.open("config/database.yaml"))
    @block  = {:adapter => DBUtilities["adapter"], :host => DBUtilities["host"],
                    :username => DBUtilities["username"], :password => DBUtilities["password"],
                    :database => DBUtilities["database"]}
  end

  load_config

  #def self.config_block
  #  @block
  #end

  def self.connect
    unless @db
      begin
        adapter = DBUtilities["adapter"]
        db_name = DBUtilities["database"]
        if adapter == "sqlite3"
          if File.exist?(DBUtilities["database"])
            @db = SQLite3::Database.open(db_name)
          else
            @db = SQLite3::Database.new(db_name)
          end
        else
          @db = Mysql2::Client.new(:host => DBUtilities["host"], :database => DBUtilities["database"],
                                   :username => DBUtilities["username"],
                                   :password => DBUtilities["password"])
        end
      rescue Mysql2::Error => e
        p "Error code:#{e.errno}"
        p "Error message:#{e.error}"
      end
    end
  end

  def self.db
    connect unless @db
    @db
  end

  def self.model_table_connection
    ActiveRecord::Base.clear_active_connections!
    if "sqlite3" == @db_config["adapter"]
      ActiveRecord::Base.establish_connection(:adapter => DBUtilities["adapter"], :database => DBUtilities["database"])
    else
      ActiveRecord::Base.establish_connection(:adapter => DBUtilities["adapter"], :host => DBUtilities["host"],
                                              :username => DBUtilities["username"], :password => DBUtilities["password"],
                                              :database => DBUtilities["database"])
    end
  end
end