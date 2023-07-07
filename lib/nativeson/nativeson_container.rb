# frozen_string_literal: true

# Copyright 2018 Ohad Dahan, Al Chou
#
#  Licensed under the Apache License, Version 2.0 (the "License");
#  you may not use this file except in compliance with the License.
#  You may obtain a copy of the License at
#
#      http://www.apache.org/licenses/LICENSE-2.0
#
#  Unless required by applicable law or agreed to in writing, software
#  distributed under the License is distributed on an "AS IS" BASIS,
#  WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
#  See the License for the specific language governing permissions and
#  limitations under the License.

class NativesonContainer
  ################################################################
  attr_accessor :reflection, :container_type, :all_columns, :all_reflections_by_name,
                :columns_string, :parent, :query, :sql, :table_name, :joins

  ################################################################
  ALLOWED_ATTRIBUTES = %i[associations columns klass limit name offset order where].freeze
  ALLOWED_ATTRIBUTES.each { |i| attr_accessor i }

  REQUIRED_JOIN_KEYS = %i[klass on foreign_on].freeze
  COLUMN_HASH_ALLOWED_KEYS = %i[as coalesce json name].freeze
  COLUMN_HASH_UNIQUE_KEYS = %i[coalesce json name].freeze
  ################################################################
  def initialize(container_type:, query:, parent: nil, name: nil)
    @parent = parent
    @container_type = container_type
    @associations = {}
    @query = query
    @klass = query[:klass].is_a?(String) ? self.class.const_get(query[:klass]) : query[:klass]
    @table_name = @klass.table_name
    @columns = query[:columns]
    @name = name.to_s
    @key = query[:key] || @name
    @joins = get_join_columns(query[:joins])
    @order = query[:order] || "#{@table_name}.#{@klass.primary_key}" || "#{@table_name}.id"
    get_all_columns
    select_columns
    get_all_reflections
    set_association_columns
    ALLOWED_ATTRIBUTES.each do |i|
      if i == :associations
        next unless query[i]

        query[i].each_pair { |k, v| create_association(k, v) }
      elsif %i[klass columns order].include?(i)
        next
      else
        instance_variable_set("@#{i}", query[i])
      end
    end
  end

  ################################################################
  def generate_sql(prefix = nil)
    container_prefix = prefix.nil? ? String.new('  ') : "#{prefix.dup}  "
    @sql = String.new('')
    @associations.each_value do |assoc_container|
      tmp_sql = assoc_container.generate_association_sql(
        prefix,
        assoc_container.generate_sql(container_prefix)
      )
      @sql << (@sql.blank? ? tmp_sql : " , #{tmp_sql}")
    end
    @sql = generate_base_sql if @parent.nil?
    @sql
  end

  ################################################################
  def generate_association_sql(prefix, tmp_sql)
    association_sql = if (reflection&.belongs_to? || reflection&.has_one?) && @column_names.any?
                        ["( SELECT JSON_BUILD_OBJECT(#{json_build_object_columns})"]
                      else
                        ["( SELECT JSON_AGG(tmp_#{table_name})"]
                      end
    association_sql << '  FROM ('
    association_sql << "    SELECT #{@columns_string}"
    association_sql << "    , #{tmp_sql}" unless tmp_sql.blank?
    association_sql << "      FROM #{table_name}"
    joins.each_value do |join|
      association_sql << "    #{join[:type]} #{join[:table_name]}"
      association_sql << "      AS #{join[:as]}" unless join[:as].blank?
      association_sql << "      ON #{join[:on]} = #{join[:foreign_on]}"
      association_sql << "      AND #{join[:where]}" unless join[:where].blank?
    end
    association_sql << "    WHERE #{@foreign_key} = #{@parent_table}"
    association_sql << "    AND #{@where}" unless @where.blank?
    association_sql << "    ORDER BY #{@order}" unless @order.blank?
    association_sql << "    LIMIT #{@limit}" unless @limit.blank?
    association_sql << "    OFFSET #{@offset}" unless @offset.blank?
    association_sql << "  ) tmp_#{table_name}"
    association_sql << ") AS #{@key}"
    association_sql.map { |i| "#{prefix}#{i}" }.join("\n")
  end

  private

  ################################################################
  def create_association(association_name, association_query)
    @associations[association_name] = NativesonContainer.new(
      container_type: :association,
      query: association_query,
      parent: self,
      name: association_name
    )
  end

  ################################################################
  def select_columns
    columns_array = []
    @column_names = []
    if @columns.blank?
      columns_array << '*'
    else
      # columns is expected to be an Array of column names (Strings) or hashes with keys :name and :as
      @columns.each do |column|
        if column.is_a? Hash
          check_column_hash(column)
          if column.key?(:coalesce)
            coalesce_array = []
            column[:coalesce].each do |coal_col|
              coalesce_array << if coal_col.to_s.split('.').one?
                                  "#{table_name}.#{coal_col}"
                                else
                                  coal_col.to_s
                                end
            end
            columns_array << "COALESCE( #{coalesce_array.join(' , ')} ) AS #{column[:as]}"
            @column_names << column[:as]
          elsif column.key?(:name)
            columns_array << if all_columns[column[:name].to_s.split('.').last]&.type == :datetime
                               "TO_CHAR(#{table_name}.#{column[:name]}, 'YYYY-MM-DD\"T\"HH24:MI:SSOF:\"00\"') AS #{column[:as]}"
                             elsif column[:name].to_s.split('.').one?
                               "#{table_name}.#{column[:name]} AS #{column[:as]}"
                             else
                               "#{column[:name]} AS #{column[:as]}"
                             end
            @column_names << column[:as]
          elsif column.key?(:json)
            columns_array << if column[:json].to_s.split('.').one?
                               "#{table_name}.#{column[:json]} AS #{column[:as]}"
                             else
                               "#{column[:json]} AS #{column[:as]}"
                             end
            @column_names << column[:as]
          end
        else # column should be a string or symbol
          check_column(column)
          columns_array << if all_columns[column.to_s.split('.').last]&.type == :datetime
                             "TO_CHAR(#{table_name}.#{column}, 'YYYY-MM-DD\"T\"HH24:MI:SSOF:\"00\"') AS #{column}"
                           elsif column.to_s.split('.').one?
                             "#{table_name}.#{column}"
                           else
                             column.to_s
                           end
          @column_names << column.to_s.split('.').last
        end
      end
    end
    @columns_string = columns_array.join(' , ')
  end

  ################################################################
  def json_build_object_columns
    column_string = @column_names.map { |i| "'#{i}' , #{i}" }.join(' , ')
    associations.each_value do |assoc_container|
      if assoc_container.reflection.has_one? || assoc_container.reflection.belongs_to?
        column_string << " , '#{assoc_container.instance_variable_get(:@key)}' , #{assoc_container.instance_variable_get(:@key)}"
      end
    end
    column_string
  end

  ################################################################
  def check_column(column_name)
    json_relation = column_name.to_s.split(/[-#]>+/).first
    column_relation = json_relation.split('.')
    if column_relation.size == 1
      unless all_columns.key?(json_relation)
        raise ArgumentError,
              "#{__method__} :: column '#{column_name}' wasn't found in the ActiveRecord #{@klass.name} columns"
      end
    elsif column_relation.size == 2
      table = column_relation.first
      name = column_relation.last
      raise ArgumentError, "#{__method__} :: column '#{name}' wasn't found in '#{table}' columns" unless joins.dig(
        table.to_sym, :column_names
      )&.include?(name)
    end
  end

  ################################################################
  def check_column_hash(column_hash)
    keys = column_hash.keys
    raise ArgumentError, "#{__method__} :: column '#{column_hash}' is missing ':as' key" unless keys.include?(:as)

    if (COLUMN_HASH_UNIQUE_KEYS & keys).size > 1
      raise ArgumentError,
            "#{__method__} :: column '#{column_hash}' can only have one of #{COLUMN_HASH_UNIQUE_KEYS.join(', ')} keys"
    end

    if keys.include?(:coalesce)
      column_hash[:coalesce].each { |coalesce_column| check_column(coalesce_column) }
    else
      check_column(column_hash[:name] || column_hash[:json])
    end
  end

  ################################################################
  def set_association_columns
    return if @parent.nil?

    unless @parent.all_reflections_by_name.key?(@name)
      raise ArgumentError,
            "#{__method__} :: #{@name} can't be found in #{@parent.name} reflections"
    end

    @reflection = @parent.all_reflections_by_name[@name]

    if reflection.through_reflection? && !(query.key?(:joins) &&
             (query.dig(:joins, 0, :foreign_on).split('.').first == @parent.table_name ||
             query.dig(:joins, 0, :on).split('.').first == @parent.table_name))
      new_join = {
        klass: reflection.through_reflection.class_name,
        table_name: reflection.through_reflection.table_name,
        on: "#{reflection.through_reflection.table_name}.#{reflection.through_reflection.join_primary_key}",
        foreign_on: "#{@parent.table_name}.#{@parent.klass.primary_key}",
        type: 'INNER JOIN'
      }
      @joins[reflection.through_reflection.name] ||= new_join
      through_reflection = true
    end

    foreign_table_name = reflection.belongs_to? ? @parent.table_name : reflection.table_name
    parent_table_name = if through_reflection
                          reflection.through_reflection.table_name
                        elsif reflection.belongs_to?
                          reflection.table_name
                        else
                          @parent.klass.table_name
                        end
    @parent_table = if @parent.container_type == :base
                      "#{parent_table_name}.#{@klass.primary_key}"
                    else
                      "#{parent_table_name}.#{@parent.klass.primary_key}"
                    end
    @foreign_key = "#{foreign_table_name}.#{reflection.foreign_key}"
  end

  ################################################################
  def generate_base_sql
    base_sql = []
    base_sql << if @key.blank?
                  'SELECT JSON_AGG(t)'
                else
                  "SELECT JSON_BUILD_OBJECT('#{@key}', JSON_AGG(t))"
                end
    base_sql << '  FROM ('
    base_sql << "    SELECT #{@columns_string}"
    base_sql << "    , #{@sql}" unless @sql.blank?
    base_sql << "    FROM #{table_name}"
    joins.each_value do |join|
      base_sql << "    #{join[:type]} #{join[:table_name]}"
      base_sql << "      AS #{join[:as]}" unless join[:as].blank?
      base_sql << "      ON #{join[:on]} = #{join[:foreign_on]}"
      base_sql << "      AND #{join[:where]}" unless join[:where].blank?
    end
    base_sql << "    WHERE #{@where}" unless @where.blank?
    base_sql << "    ORDER BY #{@order}"
    base_sql << "    LIMIT #{@limit}" unless @limit.blank?
    base_sql << "    OFFSET #{@offset}" unless @offset.blank?
    base_sql << '  ) t;'
    base_sql.join("\n")
  end

  ################################################################
  def get_all_columns
    @all_columns = {}
    @klass.columns.each { |i| @all_columns[i.name] = i }
  end

  ################################################################
  def get_join_columns(join_array)
    return {} if join_array.nil?

    join_array.map do |join|
      unless join.is_a?(Hash) && ((REQUIRED_JOIN_KEYS & join.keys) == REQUIRED_JOIN_KEYS)
        raise ArgumentError,
              "#{__method__} :: joins requires klass, on, and foreign_on keys"
      end

      join_class = self.class.const_get(join[:klass])
      join_table_name = join_class.table_name
      [
        (join[:as] || join_table_name).to_sym,
        {
          klass: join_class,
          table_name: join_table_name,
          column_names: join_class.column_names,
          on: join[:on],
          foreign_on: join[:foreign_on],
          as: join[:as],
          where: join[:where],
          type: join[:type] || 'LEFT OUTER JOIN'
        }.compact
      ]
    end.to_h
  end

  ################################################################
  def get_all_reflections
    @all_reflections_by_name = @klass.reflections
  end
  ################################################################
end
