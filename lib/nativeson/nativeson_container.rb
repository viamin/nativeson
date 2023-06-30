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
  ALLOWED_ATTRIBUTES = %i[where order limit columns associations klass name].freeze
  ALLOWED_ATTRIBUTES.each { |i| attr_accessor i }
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
    get_all_columns
    select_columns
    get_all_reflections
    get_parent_table
    get_foreign_key
    ALLOWED_ATTRIBUTES.each do |i|
      if i == :associations
        next unless query[i]

        query[i].each_pair { |k, v| create_association(k, v) }
      elsif %i[klass columns].include?(i)
        next
      else
        instance_variable_set("@#{i}", query[i])
      end
    end
  end

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
    if @columns.blank?
      columns_array << '*'
    else
      # columns is expected to be an Array of column names (Strings) or hashes with keys :name and :as
      @columns.each_with_index do |column, _idx|
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
          elsif column.key?(:name)
            columns_array << if column[:name].to_s.split('.').one?
                               "#{table_name}.#{column[:name]} AS #{column[:as]}"
                             else
                               "#{column[:name]} AS #{column[:as]}"
                             end
          end
        else # column should be a string or symbol
          check_column(column)
          columns_array << if all_columns[column.to_s]&.type == :datetime
                             "TO_CHAR(#{table_name}.#{column}, 'YYYY-MM-DD\"T\"HH24:MI:SSOF:\"00\"') AS #{column}"
                           elsif column.to_s.split('.').one?
                             "#{table_name}.#{column}"
                           else
                             column.to_s
                           end
        end
      end
    end
    @columns_string = columns_array.join(' , ')
  end

  ################################################################
  def check_column(column_name)
    column_relation = column_name.to_s.split('.')
    if column_relation.size == 1
      unless all_columns.key?(column_name.to_s)
        raise ArgumentError,
              "#{__method__} :: column '#{column_name}' wasn't found in the ActiveRecord #{@klass.name} columns"
      end
    elsif column_relation.size == 2
      table = column_relation.first
      name = column_relation.last
      raise ArgumentError, "#{__method__} :: column '#{name}' wasn't found in '#{table}' columns" unless joins.dig(
        table.to_sym, :column_names
      )&.include?(name)
    else
      raise ArgumentError,
            "#{__method__} :: column '#{column_name}' should only have the table name and column name separated by a dot"
    end
  end

  def check_column_hash(column_hash)
    keys = column_hash.keys
    raise ArgumentError, "#{__method__} :: column '#{column_hash}' is missing 'name' key" unless keys.include?(:as)

    if keys.include?(:name) && keys.include?(:coalesce)
      raise ArgumentError,
            "#{__method__} :: column '#{column_hash}' cannot have both :coalesce and :name keys"
    end

    if keys.include?(:coalesce)
      column_hash[:coalesce].each { |coalesce_column| check_column(coalesce_column) }
    else
      check_column(column_hash[:name])
    end
  end

  ################################################################
  def get_foreign_key
    @foreign_key = nil
    return @foreign_key if @parent.nil?

    unless @parent.all_reflections_by_name.key?(@name)
      raise ArgumentError,
            "#{__method__} :: #{@name} can't be found in #{@parent.name} reflections"
    end

    @foreign_key = @parent.all_reflections_by_name[@name].foreign_key
  end

  ################################################################
  def get_parent_table
    @parent_table = if @parent.nil?
                      table_name
                    elsif @parent.container_type == :base
                      "#{@parent.table_name}.#{@klass.primary_key}"
                    else
                      "#{@parent.klass.table_name}.#{@parent.klass.primary_key}"
                    end
  end

  ################################################################
  def generate_association_sql(_name, prefix, tmp_sql)
    association_sql = ["( SELECT JSON_AGG(tmp_#{table_name})"]
    association_sql << '  FROM ('
    association_sql << "    SELECT #{@columns_string}"
    association_sql << "     , #{tmp_sql}" unless tmp_sql.blank?
    association_sql << "      FROM #{table_name}"
    joins.each_pair do |table, join|
      association_sql << "    JOIN #{table} ON #{join[:on]} = #{join[:foreign_on]}"
    end
    association_sql << "      WHERE #{@foreign_key} = #{@parent_table}"
    association_sql << "      AND #{@where}" unless @where.blank?
    association_sql << "      ORDER BY #{@order}" unless @order.blank?
    association_sql << "      LIMIT #{@limit}" unless @limit.blank?
    association_sql << "  ) tmp_#{table_name}"
    association_sql << ") AS #{@key}"
    association_sql.map { |i| "#{prefix}#{i}" }.join("\n")
  end

  ################################################################
  def generate_base_sql
    base_sql = if @key.blank?
                 ['SELECT JSON_AGG(t)']
               else
                 ["SELECT JSON_BUILD_OBJECT('#{@key}', JSON_AGG(t))"]
               end
    base_sql << '  FROM ('
    base_sql << "    SELECT #{@columns_string}"
    base_sql << "     , #{@sql}" unless @sql.blank?
    base_sql << "    FROM #{table_name}"
    joins.each_pair do |table, join|
      base_sql << "    JOIN #{table} ON #{join[:on]} = #{join[:foreign_on]}"
    end
    base_sql << "    WHERE #{@where}" unless @where.blank?
    base_sql << "    ORDER BY #{@order}" unless @order.blank?
    base_sql << "    LIMIT #{@limit}" unless @limit.blank?
    base_sql << '  ) t;'
    base_sql.join("\n")
  end

  ################################################################
  def generate_sql(prefix = nil)
    container_prefix = prefix.nil? ? String.new('  ') : prefix.dup + '  '
    @sql = String.new('')
    @associations.each_pair do |association_name, association_container|
      tmp_sql = association_container.generate_association_sql(association_name, prefix,
                                                               association_container.generate_sql(container_prefix))
      @sql << (@sql.blank? ? tmp_sql : " , #{tmp_sql}")
    end
    @sql = generate_base_sql if @parent.nil?
    @sql
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
      unless join.is_a?(Hash) && (join.keys - %i[
        klass on foreign_on
      ]).empty?
        raise ArgumentError,
              "#{__method__} :: joins requires klass, on, and foreign_on keys"
      end

      join_class = self.class.const_get(join[:klass])
      [
        join_class.table_name.to_sym,
        {
          klass: join_class,
          column_names: join_class.column_names,
          on: join[:on],
          foreign_on: join[:foreign_on]
        }
      ]
    end.to_h
  end

  ################################################################
  def get_all_reflections
    @all_reflections_by_name = @klass.reflections
  end
  ################################################################
end
