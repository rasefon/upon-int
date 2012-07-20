# encoding: utf-8

require "yaml"
require "Framework/Operations"
require "Framework/ModelCache"
require "Framework/KlassInfoManager"
require "config/GlobalSettings"

class Dynamo
  KEY_INDEX = 'key_index'
  KEY_INDEX1 = 'key_index1'
  KEY_INDEX2 = 'key_index2'
  BASE_KEY_INDEX = 'base_key_index'

  SUBJECT_INDEX = 'subject_index'
  SUBJECT_INDEX1 = 'subject_index1'
  SUBJECT_INDEX2 = 'subject_index2'
  BASE_SUBJECT_INDEX = 'base_subject_index'

  FILE = 'file'
  FILE1 = 'file1'
  FILE2 = 'file2'
  BASE_FILE = 'base_file'

  OPERATOR = 'operator'

  OUTPUT = 'output'
  OUTPUT_KEY = 'output_key'
  OUTPUT_SUBJECT = 'output_subject'

  def self.run yaml_file
    config = YAML.load_file(yaml_file)
    config.each do |directory, block|
      unless Dir.exist? (directory)
        puts "Folder:#{directory} doesn't exist!"
        return
      end

      Dir.chdir(directory) do
        if "check" == directory
          check(block)
        else
          calculate(block)
        end
      end
    end
  end

  private
  def self.check block
    block.each do |content|
      # Key
      base_key = TableColumns[content[BASE_KEY_INDEX]]
      key = TableColumns[content[KEY_INDEX]]

      # Subject
      base_subject = TableColumns[content[BASE_SUBJECT_INDEX]]
      subject = TableColumns[content[SUBJECT_INDEX]]

      # File
      base_cache = TempTableCache.create_from_file(content[BASE_FILE])
      cache = TempTableCache.create_from_file(content[FILE])

      error_keys = Operations.check_key(base_cache, cache, base_key, key)
      if error_keys.size != 0
        File.open(content[OUTPUT_KEY], "w:#{$em.external}") do |f|
          error_keys.each { |ek| f.puts(ek) }
        end
      else
        File.delete(content[OUTPUT_KEY]) if File.exist?(content[OUTPUT_KEY])
        Operations.check_subject(base_cache, cache, key, base_subject, subject).output_to_file(content[OUTPUT_SUBJECT])
      end
    end
  end


  def self.calculate block
    block.each do |content|
      if content[OPERATOR] =~ /^e/i
        # construct key
        keys = construct_token(KEY_INDEX, content)
        # construct subjects
        subs = construct_token(SUBJECT_INDEX, content)
        # construct 2 caches
        cache = TempTableCache.create_from_file(content[FILE])

        result_cache = Operations.ein_update(cache, keys, subs, content[OPERATOR][-1])
        result_cache.output_to_file(content[OUTPUT])
      else
        # construct key
        keys1 = construct_token(KEY_INDEX1, content)
        keys2 = construct_token(KEY_INDEX2, content)

        # construct subjects
        subs1 = construct_token(SUBJECT_INDEX1, content)
        subs2 = construct_token(SUBJECT_INDEX2, content)

        # construct 2 caches
        cache1 = TempTableCache.create_from_file(content[FILE1]) if content[FILE1]
        cache2 = TempTableCache.create_from_file(content[FILE2]) if content[FILE2]

        unless cache1.empty? || cache2.empty?
          if '++' == content[OPERATOR]
            result_cache = Operations.traverse_to_concat(cache1, cache2, subs1, subs2, keys1, keys2)
          elsif content[OPERATOR] =~ /^u/i
            result_cache = Operations.traverse_to_join(cache1, cache2, subs1, subs2, keys1, keys2, content[OPERATOR][-1])
          elsif 's-' == content[OPERATOR]
            result_cache = Operations.traverse_to_set_minus(cache1, cache2, keys1, keys2)
          elsif content[OPERATOR] =~ /^e/i
          else
            result_cache = Operations.traverse_to_calculate(cache1, cache2, subs1, subs2, keys1, keys2, content[OPERATOR])
          end
          result_cache.output_to_file(content[OUTPUT])
        end
      end
    end
  end

  private

  def self.construct_token(index, content)
    token = []
    content[index].each { |i| token << TableColumns[i] } if content[index]
    token
  end

end
