# encoding: utf-8
$LOAD_PATH.unshift(File.dirname(__FILE__)) unless $LOAD_PATH.include?(File.dirname(__FILE__))

require "yaml"
require "Framework/Operations"
#require "Framework/generator"
require "Framework/EncodeManager"
#require "Framework/KlassInfoManager"
require "Framework/Dynamo"
require "Framework/ModelCache"

#DBUtilities.model_table_connection

#Generator::ModelTableGen.gen(src_file_name)
#src_klass_name = KlassNameManager.get_klass_name(src_file_name)
#if Object.const_defined?(src_klass_name.to_sym)
#  #src_klass = Object.const_get(src_klass_name.to_sym)
#  #Generator::ModelTableGen.update_table(src_file_name)
#else
#  p "Can't parse #{src_file_name}"
#end

#f1_name = "1.csv"
#f2_name = "2.csv"
#c1 = TempTableCache.create_from_file(f1_name)
#c2 = TempTableCache.new(f2_name)
#c2 = TempTableCache.create_from_file(src_file_name)
#subject = []
#subject << TableColumns[9]
#keys = []
#keys << TableColumns[5]

#result = Operations.traverse(c1, c2, subject, keys, keys) { |i1, i2| i1.to_i == i2.to_i }
#result.each { |item| p item }

Dynamo.run(ARGV[0])
#Dynamo.run("run.example.yaml")