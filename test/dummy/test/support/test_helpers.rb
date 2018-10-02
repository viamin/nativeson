module TestHelpers
  ############################################################
  def self.fetch_models
    models = []
    Dir.foreach('test/dummy/app/models').each do |model_file|
      next if model_file.match(/^\.+$|application_record|concerns/)
      model_name = model_file.gsub(/\.rb$/,'').camelize
      begin
        model = Object.const_get(model_name)
        models << model if model < ApplicationRecord
      rescue NameError => e
        highlight_text("#{__method__} :: model_name = '#{model_name}' couldn't be fetched via const_get, exception: #{e}")
      end
    end
    models
  end
  ############################################################
  def self.highlight_text(text)
    puts text.colorize(color: :light_white, background: :black)
  end
  ############################################################
  def self.apply_needed_casting(key, ar_instance, nativeson_hash)
    case ar_instance.send(key)
    when ActiveSupport::TimeWithZone
      ar_val = ar_instance.send(key).to_f.round(3).to_s
      nativeson_val = nativeson_hash[key].to_datetime.to_f.round(3).to_s
    when Float
      ar_val = ar_instance.send(key).round(3).to_s
      nativeson_val = nativeson_hash[key].round(3).to_s
    when Integer
      ar_val = ar_instance.send(key).to_s
      nativeson_val = nativeson_hash[key].to_s
    else
      ar_val = ar_instance.send("#{key}_before_type_cast").to_s
      nativeson_val = nativeson_hash[key].to_s
    end
    return ar_val, nativeson_val
  end
  ############################################################
  def self.compare_ar_instance_to_nativeson_hash(ar_instance, nativeson_hash, columns_to_ignore = %w())
    equal = true
    (ar_instance.attributes.keys + nativeson_hash.keys).uniq.each do |key|
      next if columns_to_ignore.include?(key) ; # Skiping due to minor casting on each side
      equal = equal && nativeson_hash.key?(key)
      unless equal
        highlight_text("#{__method__} :: Model = #{ar_instance.class} | ID = #{ar_instance.try(:id)} | nativeson_hash missing key = #{key}")
        break
      end
      equal = equal && ar_instance.attributes.key?(key)
      unless equal
        highlight_text("#{__method__} :: Model = #{ar_instance.class} | ID = #{ar_instance.try(:id)} | ar_instance missing key = #{key}")
        break
      end
      ar_val, nativeson_val = apply_needed_casting(key, ar_instance, nativeson_hash)
      equal = equal && (ar_val == nativeson_val)
      unless equal
        highlight_text("#{__method__} :: Model = #{ar_instance.class} | ID = #{ar_instance.try(:id)}")
        highlight_text("#{__method__} :: key = #{key} | ar_val = #{ar_val} | nativeson_val = #{nativeson_val}")
        break
      end
    end
    equal
  end
  ############################################################
  def self.map_nativeson_by_prop(nativeson_array, prop = 'id')
    hash = {}
    nativeson_array.each { |i| hash[i[prop]] =  i }
    unless hash.size == nativeson_array.size
      # Make sure the conversion didn't lose any data
      raise ArgumentError.new("#{__method__} Input array and output hash differ in size, prop = #{prop}")
    end
    hash
  end
  ############################################################
  def self.random_attributes(ar_instance, ignore_attributes: %w(),
                             mandatory_attributes: %w(id), size_limit: 3)
    output_attributes = Set.new(mandatory_attributes)
    ar_attribute_names = ar_instance.attribute_names
    ar_attribute_names.reject! { |name| mandatory_attributes.include?(name) || ignore_attributes.include?(name) }
    return (output_attributes + ar_attribute_names.sample(size_limit)).to_a
  end
  ############################################################
end
