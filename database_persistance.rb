require "pg"

class DatabasePersistance
  def initialize(logger)
    @db = PG.connect(dbname: "todos")
    @logger = logger
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
    # id = next_list_id(@session[:lists])
    # @session[:lists] << { id: id, name: list_name, todos: [] }
  end

  def delete_list(id)
    # @session[:lists].delete_if { |list| list[:id] == id }
  end

  def update_list_name(id, new_name)
    # find_list(id)[:name] = new_name
  end

  def add_todo(list_id, name)
    # list = find_list(list_id)
    # todo_id = next_todo_id(list[:todos])
    # list[:todos] << {id: todo_id, name: name, completed: false}
  end

  def complete_all_todos(id)
    # list = find_list(id)
    # todos = list[:todos]
    # todos.each do |todo|
      # todo[:completed] = true
    # end
  end

  def update_todo_status(list_id, todo_id, new_status)
    # list = find_list(list_id)
    # todo = list[:todos].find { |t| t[:id] == todo_id }
    # todo[:completed] = new_status
  end

  def delete_todo(list_id, todo_id)
    # list = find_list(list_id)
    # list[:todos].delete_if { |todo| todo[:id] == todo_id }
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
