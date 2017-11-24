require_relative 'db_connection'
require 'active_support/inflector'
# NB: the attr_accessor we wrote in phase 0 is NOT used in the rest
# of this project. It was only a warm up.

class SQLObject
  def self.columns
    # ...
    @columns ||= DBConnection.execute2(<<-SQL).first.map(&:to_sym)

    SELECT
      *
    FROM
      #{table_name}
  SQL
  end

  def self.finalize!
    self.columns.each do |column|
      define_method(column) do
        self.attributes[column]
      end
      
      define_method("#{column}=") do |value|
        self.attributes[column] = value
      end 
    end
  end

  def self.table_name=(table_name)
    # ...
    @table_name = table_name
  end

  def self.table_name
    # ...
    words = self.name.downcase.split(' ')
    words.join('_') + 's' || @table_name
  end

  def self.all
    # ...
    results = DBConnection.execute(<<-SQL)
      SELECT 
        * 
      FROM 
        #{table_name}
    SQL
    self.parse_all(results)
  end

  def self.parse_all(results)
    # ...
    results.map do |result|
      self.new(result)
    end
  end

  def self.find(id)
    # ...
    self.all.find { |obj| obj.id == id }
  end

  def initialize(params = {})
    # ...
    params.each do |attr_name, value|
      attr_name = attr_name.to_sym
      if self.class.columns.include?(attr_name)
        send("#{attr_name}=", value) 
      else 
        raise "unknown attribute '#{attr_name}'"
      end
    end
  end

  def attributes
    # ...
    @attributes ||= {}
  end

  def attribute_values
    # ...
    self.class.columns.map { |column| send(column) }
  end

  def insert
    # ...
    col_names = self.class.columns.join(", ")
    question_marks = (["?"] * attribute_values.count).join(", ")
    
    DBConnection.execute(<<-SQL, attribute_values)
    INSERT INTO
      #{self.class.table_name} (#{col_names})
    VALUES
      (#{question_marks})
    SQL
    self.id = DBConnection.last_insert_row_id
  end

  def update
    # ...
    set_line = self.class.columns
      .map { |attr_name| "#{attr_name} = ?" }.join(", ")

    DBConnection.execute(<<-SQL, attribute_values, id)
      UPDATE
        #{self.class.table_name}
      SET
        #{set_line}
      WHERE
        #{self.class.table_name}.id = ?
    SQL
  end

  def save
    # ...
    if id.nil?
      self.insert 
    else 
      self.update
    end
  end
end
