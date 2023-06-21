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
  attr_accessor :reflection, :container_type
  attr_accessor :all_columns, :all_reflections_by_name, :columns_string, :parent, :query, :sql
  ################################################################
  ALLOWED_ATTRIBUTES = [:where, :order, :limit, :columns, :associations, :klass, :name]
  CONTAINER_TYPES = [:base, :asscoation]
  ALLOWED_ATTRIBUTES.each { |i| attr_accessor i }
  ################################################################
  def initialize(container_type:, query:, parent: nil, name: nil)
    @parent = parent
    @container_type = container_type
    @associations = {}
    @query = query
    @klass = query[:klass].is_a?(String) ? self.class.const_get(query[:klass]) : query[:klass]
    @columns = query[:columns]
    @name = name.to_s
    get_all_columns
    select_columns
    get_all_reflections
    get_parent_table
    get_foreign_key
    ALLOWED_ATTRIBUTES.each do |i|
      if i == :associations
        next unless query[i]
        query[i].each_pair { |k, v| create_association(k, v) }
      elsif [:klass, :columns].include?(i)
        next
      else
        instance_variable_set("@#{i}", query[i])
      end
    end
  end

  ################################################################
  def create_association(association_name, association_query)
    @associations[association_name] = NativesonContainer.new(container_type: :association, query: association_query, parent: self, name: association_name)
  end

  ################################################################
  def select_columns
    @columns_string = ""
    if @columns.blank?
      @columns_string << "*"
    else
      @columns.each_with_index do |column, idx|
        raise ArgumentError.new("#{__method__} :: column '#{column}' wasn't found in the ActiveRecord #{@klass.name} columns") unless all_columns.key?(column)
        @columns_string << " , " if idx > 0
        @columns_string << column
      end
    end
  end

  ################################################################
  def get_foreign_key
    @foreign_key = nil
    return @foreign_key if @parent.nil?
    raise ArgumentError.new("#{__method__} :: #{@name} can't be found in #{@parent.name} reflections") unless @parent.all_reflections_by_name.key?(@name)
    @foreign_key = @parent.all_reflections_by_name[@name].foreign_key
  end

  ################################################################
  def get_parent_table
    @parent_table = if @parent.nil?
      @klass.table_name
    elsif @parent.container_type == :base
      "base_table.#{@klass.primary_key}"
    else
      "#{@parent.klass.table_name}.#{@parent.klass.primary_key}"
    end
  end

  ################################################################
  def generate_association_sql(name, prefix, tmp_sql)
    "
    ( SELECT JSON_AGG(tmp_#{@klass.table_name} )
        FROM (
          SELECT #{@columns_string}
          #{" , " + tmp_sql unless tmp_sql.blank?}
          FROM   #{@klass.table_name}
          WHERE  #{@foreign_key} = #{@parent_table}
          #{"AND " + @where.to_s unless @where.blank?}
          #{"ORDER BY " + @order.to_s unless @order.blank?}
          #{"LIMIT " + @limit.to_s unless @limit.blank?}
         ) tmp_#{@klass.table_name}
     ) AS #{name}
    ".split("\n").map { |i| "#{prefix}#{i}" }.join("\n")
  end

  ################################################################
  def generate_base_sql
    "
    SELECT JSON_AGG(t)
       FROM (
        SELECT #{@columns_string}
        #{" , " + @sql unless @sql.blank?}
        FROM #{@klass.table_name}
        AS base_table
        #{"WHERE " + @where.to_s unless @where.blank?}
        #{"ORDER BY " + @order.to_s unless @order.blank?}
        #{"LIMIT " + @limit.to_s unless @limit.blank?}
      ) t;
    "
  end

  ################################################################
  def generate_sql(prefix = "")
    prefix << "  "
    @sql = ""
    @associations.each_pair do |association_name, association_data|
      tmp_sql = association_data.generate_association_sql(association_name, prefix, association_data.generate_sql(prefix))
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
  def get_all_reflections
    @all_reflections_by_name = @klass.reflections
  end
  ################################################################
end
