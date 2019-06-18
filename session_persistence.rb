class SessionPersistence
  def initialize(session)
    @session = session
    @session[:lists] ||= []
  end

  def find_list(id)
    @session[:lists].find { |list| list[:id] == id }
  end

  def all_lists
    @session[:lists]
  end

  def create_new_list(list_name)
    id = next_list_id(@session[:lists])
    @session[:lists] << { id: id, name: list_name, todos: [] }
  end

  def delete_list(id)
    @session[:lists].delete_if { |list| list[:id] == id }
  end

  def update_list_name(id, new_name)
    find_list(id)[:name] = new_name
  end

  def add_todo(list_id, name)
    list = find_list(list_id)
    todo_id = next_todo_id(list[:todos])
    list[:todos] << {id: todo_id, name: name, completed: false}
  end

  def complete_all_todos(id)
    list = find_list(id)
    todos = list[:todos]
    todos.each do |todo|
      todo[:completed] = true
    end
  end

  def update_todo_status(list_id, todo_id, new_status)
    list = find_list(list_id)
    todo = list[:todos].find { |t| t[:id] == todo_id }
    todo[:completed] = new_status
  end

  def delete_todo(list_id, todo_id)
    list = find_list(list_id)
    list[:todos].delete_if { |todo| todo[:id] == todo_id }
  end

  private

  def next_list_id(lists)
    max = lists.map { |list| list[:id] }.max || 0
    max + 1
  end

  def next_todo_id(todos)
    max = todos.map { |todo| todo[:id] }.max || 0
    max + 1
  end
end
