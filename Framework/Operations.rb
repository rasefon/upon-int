# encoding: utf-8
require "Framework/EncodeManager"

module Operations
  def self.check_key(base_cache, cache, base_key, key)
    error_keys = []
    # Check the key, if the key is not in the base key collection, log it first!
    cache.each do |c|
      has_key = false
      base_cache.each do |bc|
        has_key = true if c[key] and bc[base_key] and c[key].strip == bc[base_key].strip
      end
      error_keys << c[key] unless has_key
    end
    error_keys
  end

  def self.check_subject(base_cache, cache, key, base_subject, subject)
    error_subjects = TempTableCache.create

    # Set title
    temp_hash = Hash.new
    temp_hash[TableColumns[0]] = cache.titles[key]
    temp_hash[TableColumns[1]] = cache.titles[subject]
    error_subjects.titles = temp_hash

    cache.each do |c|
      ttc = TempTableCache.create
      base_cache.each do |bc|
        next unless bc.has_value?(c[key])
        ttc << bc
      end

      has_one = false
      ttc.each do |tc|
        if tc[base_subject] and c[subject] and tc[base_subject].strip == c[subject].strip
          has_one = true
          break
        end
      end

      unless has_one
        temp_hash = Hash.new
        temp_hash[TableColumns[0]] = c[key]
        temp_hash[TableColumns[1]] = c[subject]
        error_subjects << temp_hash
      end
    end
    error_subjects
  end

  def self.traverse_to_calculate(cache1, cache2, subjects1, subjects2, keys1, keys2, op)
    if keys1.size != keys2.size
      puts "Can't compare these two files #{cache1},#{cache2} because the number of keys are different."
      return
    end

    result = TempTableCache.create
    temp_hash = Hash.new
    # set keys for titles
    keys1.each { |k| temp_hash[k] = cache1.titles[k] }
    # set subjects for titles
    subjects1.each { |s| temp_hash[s] = cache1.titles[s] }
    result.titles = temp_hash

    traverse(cache1, cache2, keys1, keys2) do |c1, c2|
      temp_hash = Hash.new
      subjects1.each_index do |si|
        ret_val = compute(c1[subjects1[si]], c2[subjects2[si]], op)
        keys1.each { |k| temp_hash[k] = c1[k] }
        temp_hash[subjects1[si]]= ret_val.to_s
      end
      result << temp_hash
    end
    result
  end

  def self.ein_update(cache, keys, subjects, op)
    result = TempTableCache.create
    temp_hash = Hash.new
    # set keys for titles
    keys.each { |k| temp_hash[k] = cache.titles[k] }
    # set subjects for titles
    subjects.each { |s| temp_hash[s] = cache.titles[s] }
    result.titles = temp_hash
    cache.delete_at(0)

    # Caching for result
    # result_cache: {key: {sub_key: sub_value}, ...}}
    result_cache = Hash.new

    cache.each do |c|
      tk = ''
      keys.each { |k| tk << c[k].to_s.strip if c[k] }
      if result_cache.has_key?(tk)
        sub_h = result_cache[tk]
        subjects.each do |sk|
          sub_h[sk] = compute(sub_h[sk], c[sk], op)
        end
      else
        sub_h = Hash.new
        keys.each { |k| sub_h[k] = c[k] }
        subjects.each { |sk| sub_h[sk] = c[sk] }
        result_cache[tk] = sub_h
      end
    end

    #result_cache.each { |k, v| puts "#{k}: #{v}" }
    
    result_cache.each_value do |rv|
      temp_hash = Hash.new
      keys.each { |k| temp_hash[k] = rv[k] }
      subjects.each { |s| temp_hash[s] = rv[s] }
      result << temp_hash
    end
    result
  end

  #def self.traverse_to_calculate_same(cache1, cache2, subjects, keys, op, &block)
  #  traverse_to_calculate(cache1, cache2, subjects, subjects, keys, keys, op) { |c1, c2| block.call(c1, c2) }
  #end

  def self.traverse_to_concat(cache1, cache2, subjects1, subjects2, keys1, keys2)
    result = TempTableCache.create
    temp_hash = Hash.new
    # set keys for titles
    index = 1
    keys1.each { |k| temp_hash[TableColumns[index]] = cache1.titles[k]; index += 1 }
    # set subjects for titles
    subjects1.each { |s| temp_hash[TableColumns[index]] = cache1.titles[s]; index += 1 }
    subjects2.each { |s| temp_hash[TableColumns[index]] = cache2.titles[s]; index += 1 }
    result.titles = temp_hash


    #puts result.titles.values
    traverse(cache1, cache2, keys1, keys2) do |c1, c2|
      index = 1
      temp_hash = Hash.new
      keys1.each { |k| temp_hash[TableColumns[index]] = c1[k]; index += 1 }
      subjects1.each { |s| temp_hash[TableColumns[index]] = c1[s]; index += 1 }
      subjects2.each { |s| temp_hash[TableColumns[index]] = c2[s]; index += 1 }
      result << temp_hash
    end
    result
  end

  def self.traverse_to_set_minus(base, cache, keys1, keys2)
    result = TempTableCache.create
    # set keys for titles
    result.titles = base.titles

    has_one = false
    base.each do |b|
      cache.each do |c|
        has_one = false
        keys1.each_index do |i|
          has_one = true if b[keys1[i]] and c[keys2[i]] and b[keys1[i]].strip == c[keys2[i]].strip
        end
        break if has_one
      end

      result << b unless has_one
    end
    result
  end

  def self.traverse_to_join(cache1, cache2, subjects1, subjects2, keys1, keys2, op)
    if cache1 and cache2 and cache1[0].size != cache2[0].size
      puts 'The structure of 2 tables are different, can not do join operation'
      return
    end

    result = traverse_to_calculate(cache1, cache2, subjects1, subjects2, keys1, keys2, op)

    left_result = set_minus(cache1, result, keys1, subjects1)
    right_result = set_minus(cache2, result, keys2, subjects2)

    result.concat(left_result)
    result.concat(right_result)
  end

  def self.compute(data1, data2, op)
    if "==" == op
      return eval("#{data1.to_s} #{op} #{data2.to_s}")
    elsif %w{+ - * /}.include?(op)
      return eval("#{data1.to_i} #{op} #{data2.to_i}")
    else
      puts "Unknown operator: #{op} !"
    end
  end

  def self.traverse(cache1, cache2, keys1, keys2)
    if keys1.size != keys2.size
      puts "Can't compare these two files #{cache1},#{cache2} because the number of keys are different."
      return
    end

    cache1.each do |c1|
      cache2.each do |c2|
        same_one = true
        # compare all the keys according to consequence.
        keys1.each_index do |i|
          same_one &&= (c1[keys1[i]] and c2[keys2[i]] and (c1[keys1[i]].strip == c2[keys2[i]].strip))
        end
        yield(c1, c2) if same_one
      end
    end
  end

  private
  # union the cache and result if the result doesn't contains cache.
  def self.set_minus(cache1, cache2, keys, subjects)
    result = []
    cache1.each do |c1|
      # test if r contains c1
      has_key = false
      cache2.each do |c2|
        keys.each do |k|
          if c1[k] and c2.has_value?(c1[k])
            has_key = true
            break
          end
        end
      end

      unless has_key
        temp_hash = Hash.new
        keys.each { |k| temp_hash[k] = c1[k] }
        subjects.each { |s| temp_hash[s] = c1[s] }
        result << temp_hash
      end
    end

    result
  end

end
