require "pry"

class Dog
  attr_accessor :name, :breed, :id
  attr_writer
  attr_reader

  def initialize(name:, breed:, id: nil)
    @name = name
    @breed = breed
    @id = id
  end

  def self.create_table
    query = <<-SQL
    CREATE TABLE IF NOT EXISTS dogs (
      id INTEGER PRIMARY KEY,
      name TEXT,
      breed TEXT
    );
    SQL
    DB[:conn].execute(query)
  end

  def self.drop_table
    query = <<-SQL
    DROP TABLE IF EXISTS dogs;
    SQL
    DB[:conn].execute(query)
  end

  def save
    if self.id
      self.update
    else
      query = <<-SQL
      INSERT INTO dogs (name, breed) VALUES (?, ?)
      SQL
      DB[:conn].execute(query, self.name, self.breed)
      self.id = DB[:conn].execute("SELECT last_insert_rowid() FROM dogs")[0][0]
      self
    end
  end

  def self.create(name:, breed:)
    self.new(name: name, breed: breed).tap {|dog| dog.save}
  end

  def self.new_from_db(row)
    self.new(name: row[1], breed: row[2], id: row[0])
  end

  def self.find_by_name(name)
    query = <<-SQL
    SELECT * FROM dogs WHERE name = ?;
    SQL
    DB[:conn].execute(query, name)[0].instance_eval {|row| Dog.new_from_db(row)}
  end

  def self.find_by_id(id)
    query = <<-SQL
    SELECT * FROM dogs WHERE id = ?;
    SQL
    DB[:conn].execute(query, id)[0].instance_eval{|row| Dog.new_from_db(row)}
  end

  def update
    query = <<-SQL
    UPDATE dogs SET name = ?, breed = ? WHERE id = ?
    SQL
    DB[:conn].execute(query, self.name, self.breed, self.id)
  end

  def self.find_or_create_by(name:, breed:)
    query = <<-SQL
    SELECT * FROM dogs WHERE name = ? AND breed = ?;
    SQL
    dog = DB[:conn].execute(query, name, breed)
    #found dog; return a new dog instance with that data
    # binding.pry
    if !dog.empty?
      self.new_from_db(dog[0])
    #did not find dog, create new dog and add to db
    else
      self.create(name: name, breed: breed)
    end
  end

end
