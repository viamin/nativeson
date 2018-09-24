require "nativeson/railtie"

# Usage : include Nativeson in whatever model you want
module Nativeson
  ################################################################

  # TODO : #columns method is for future usage, when 'fetch_json_by_association_names(*associations_by_name_array)'
  #        will support an input of Hash that states association name and which columns to dump
  def columns(assoc_data)
    columns = ''
    if assoc_data.fetch(:columns,[]).empty?
      columns << '*'
    else
      assoc_data.fetch(:columns,[]).each_with_index do |column,idx|
        columns << ',' if idx > 0
        columns << "#{assoc_data[:table_name]}.#{column}"
      end
    end
    columns
  end

  ################################################################

  # TODO : Helper methods, need to convert to ClassMethods since they depend only on the input argument
  def association_name(assoc)
    assoc.name.to_s.freeze
  end

  def association_table_name(assoc)
    assoc.klass.table_name.freeze
  end

  def association_type(assoc)
    case assoc.class.to_s
    when 'ActiveRecord::Reflection::HasManyReflection'
      :has_many
    when 'ActiveRecord::Reflection::HasOneReflection'
      :has_one
    else
      raise ArgumentError.new("#{assoc.class} of #{assoc.klass.table_name.freeze} is unsupported")
    end
  end

  def association_data(assoc)
    {
        table_name: association_table_name(assoc),
        name: association_name(assoc),
        type: association_type(assoc),
        foreign_key: assoc.foreign_key
    }
  end

  def get_association_data(associations_by_name_hash)
    associations_data = []
    (associations_by_name_hash.empty? ? @all_associations_by_name_hash : associations_by_name_hash).each_value do |assoc|
      associations_data << association_data(assoc)
    end
    associations_data
  end

  def verify_input_associations(associations_by_name_hash)
    associations_by_name_hash.each_key do |name|
      val = @all_associations_by_name_hash[name]
      raise ArgumentError.new("#{__method__} => #{name}") if val.nil?
      associations_by_name_hash[name] = val
    end
  end


  def association_query_string(association_data_hash)
    "( SELECT JSON_AGG(tmp_#{association_data_hash[:table_name]} )
        FROM (
             SELECT * FROM #{association_data_hash[:table_name]} WHERE #{association_data_hash[:table_name]}.#{association_data_hash[:foreign_key]} = base_table.id
         ) tmp_#{association_data_hash[:table_name]}
    ) AS #{association_data_hash[:name]}"
  end

  def build_json_query(association_data_array)
    association_sql = String.new
    association_data_array.each_with_index do |assoc,idx|
      association_sql << ','.freeze if idx > 0
      association_sql << association_query_string(assoc)
    end
    "SELECT JSON_AGG(t)
        FROM (
          SELECT *, #{association_sql} FROM #{self.class.table_name} AS base_table
      ) t;"
  end

  def to_json_agg_qeury(input, raw=false)
    return "select json_agg(t) from (#{input}) t;" if raw
    [ActiveRecord::Relation, ActiveRecord::AssociationRelation].each do |type|
      return "select json_agg(t) from (#{input.to_sql}) t;" if input.class.ancestors.include?(type)
    end
    raise ArgumentError.new("#{__method__} input class '#{input.class.to_s}' is the wrong type")
  end

  def send_query_to_db(sql, fetch_name: 'json_agg')
    ActiveRecord::Base.connection.exec_query(sql)[0].fetch(fetch_name)
  end

  def fetch_json_agg(input, raw = false)
    ActiveRecord::Base.connection.exec_query(to_json_agg_qeury(input, raw))[0].fetch('json_agg')
  end

  def convert_to_hash(*associations_by_name_array)
    associations_by_name_array.map {|i| [i, nil]}.to_h
  end

  ################################################################

  # TODO : Need to get rid of the instance variable @all_associations_by_name_hash to prevent poluting the instance
  #        we're in, can be done by flatting the scope via :send/:instance_eval

  def all_associations_by_name
    @all_associations_by_name_hash = {}
    self.class.reflect_on_all_associations.each do |assoc|
      @all_associations_by_name_hash[assoc.klass.table_name.freeze] = assoc
    end
    @all_associations_by_name_hash
  end

  ################################################################
  # The main methods that return the end result

  def fetch_json_by_association_names(*associations_by_name_array)
    all_associations_by_name
    associations_by_name_hash = convert_to_hash(*associations_by_name_array)
    verify_input_associations associations_by_name_hash unless associations_by_name_hash.empty?
    association_data_array = get_association_data(associations_by_name_hash)
    send_query_to_db(build_json_query(association_data_array))
  end

  ################################################################
end

