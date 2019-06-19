require "pg"

class DatabasePersistence
  def initialize(logger)
    @db = PG.connect(ENV['DATEBASE_URL'])
    # @db = if Sinatra::Base.production?
    #   PG.connect(ENV['DATEBASE_URL'])
    # else
    #   PG.connect(dbname: "todos")
    # end
    @logger = logger
  end

  def disconnect
    @db.close
  end

  def query(statement, *params)
    @logger.info("#{statement}: #{params}")
    @db.exec_params(statement, params)
  end

  def find_list(id)
    sql = "SELECT * FROM lists WHERE id = $1"
    result = query(sql, id)

    tuple = result.first
    todos = find_todos(tuple["id"])
    {id: tuple["id"].to_i, name: tuple["name"], todos: todos}
  end

  def all_lists
    sql = "SELECT * FROM lists;"
    result = query(sql)
    result.map do |tuple|
      todos = find_todos(tuple["id"])
      {id: tuple["id"].to_i, name: tuple["name"], todos: todos}
    end
  end

  def create_new_list(list_name)
    sql = "INSERT INTO lists (name) VALUES ($1);"
    query(sql, list_name)
  end

  def delete_list(id)
    query("DELETE FROM todos WHERE list_id = $1;", id)
    query("DELETE FROM lists WHERE id = $1;", id)
  end

  def update_list_name(id, new_name)
    sql = "UPDATE lists SET name = $1 WHERE id = $2;"
    query(sql, new_name, id)
  end

  def add_todo(list_id, name)
    sql = "INSERT INTO todos (name, list_id) VALUES ($1, $2);"
    query(sql, name, list_id)
  end

  def complete_all_todos(id)
    sql = "UPDATE todos SET completed = true WHERE list_id = $1;"
    query(sql, id)
  end

  def update_todo_status(list_id, todo_id, new_status)
    sql = "UPDATE todos SET completed = $1 WHERE id = $2 AND list_id = $3;"
    query(sql, new_status, todo_id, list_id)
  end

  def delete_todo(list_id, todo_id)
    sql = "DELETE FROM todos WHERE list_id = $1 AND id = $2;"
    query(sql, list_id, todo_id)
  end

  private

  def find_todos(id)
    sql = "SELECT * FROM todos WHERE list_id = $1"
    result = query(sql, id)
    result.map do |tuple|
      {id: tuple["id"].to_i, name: tuple["name"], completed: tuple["completed"] == "t" }
    end
  end
end
