require 'sinatra' 
require 'sinatra/content_for'
require 'tilt/erubis'
require 'pry'
require 'rack'

require_relative "database_persistence"

configure do
  enable :sessions
  set :session_secret, 'secret'
  set :erb, :escape_html => true

end

configure(:development) do
  require 'sinatra/reloader'
  also_reload "database_persistence.rb"
end

helpers do
  def todos_remaining(list)
    list[:todos].count { |todo| !todo[:completed] }
  end

  def list_completed?(list)
    todos_remaining(list) == 0 && list[:todos].size > 0
  end

  def list_class(list)
    if list_completed?(list)
      "complete"
    end
  end

  def sort_lists(lists, &block)
    complete_lists, incomplete_lists = lists.partition { |list| list_completed?(list) }

    incomplete_lists.each(&block)
    complete_lists.each(&block)
  end

  def sort_todos(todos, &block)
    complete_todos, incomplete_todos = todos.partition { |todo| todo[:completed] }

    incomplete_todos.each { |todo| yield todo, todos.index(todo) }
    complete_todos.each { |todo| yield todo, todos.index(todo) }
  end
end

def load_list(list_id)
  list = @storage.find_list(list_id)
  return list if list

  session[:error] = "The specified list does not exist."
  redirect "/lists"
end


# Sets the session before each request
before do
  @storage = DatabasePersistence.new(logger)
end

# Home page sends to list page
get '/' do
  redirect '/lists'
end

# Renders the list of lists
get '/lists' do
  @lists = @storage.all_lists
  erb :lists, layout: :layout
end

# Opens page to add new list
get '/lists/new' do
  erb :new_list, layout: :layout
end

# List name input validation, return a string as error
def error_for_list_name(name)
  if !name.size.between?(1, 101)
    'List name must be between 1 and 100 characters.'
  elsif @storage.all_lists.any? { |list| list[:name] == name }
    'List name must be unique.'
  end
end

# Sends form with new list info
post '/lists' do
  list_name = params[:list_name].strip

  error = error_for_list_name(list_name)
  if error
    session[:error] = error
    erb :new_list, layout: :layout
  else
    @storage.create_new_list(list_name)
    session[:success] = 'The list has been created.'
    redirect '/lists'
  end
end

# Display a list
get '/lists/:id' do
  id = params[:id].to_i
  @list = load_list(id)
  @list_name = @list[:name]
  @list_id = @list[:id]
  @todos = @list[:todos]
  erb :list, layout: :layout
end

#Edit existing todo list
get '/lists/:id/edit' do
  @list_id = params[:id]
  @list = load_list(@list_id.to_i)
  erb :edit_list, layout: :layout
end

# Submit new list name
post "/lists/:id" do
  list_name = params[:list_name].strip
  @list_id = params[:id].to_i
  @list = load_list(@list_id)

  error = error_for_list_name(list_name)
  if error
    session[:error] = error
    erb :edit_list, layout: :layout
  else
    @storage.update_list_name(@list_id, list_name)
    session[:success] = 'The list has been successfully renamed.'
    redirect "/lists/#{@list_id}"
  end
end

# Delete a list
post "/lists/:id/delete" do
  @list_id = params[:id].to_i

  @storage.delete_list(@list_id)
  if env["HTTP_X_REQUESTED_WITH"] == "XMLHttpRequest"
    "/lists"
  else
    session[:success] = "The list has been deleted."
    redirect "/lists"
  end
end

def error_for_todo(name)
  if !name.size.between?(1, 101)
    'List name must be between 1 and 100 characters.'
  end
end

# Add new todo to a list
post "/lists/:list_id/todos" do
  @list_id = params[:list_id].to_i
  @list = load_list(@list_id)
  text = params[:todo].strip
  error = error_for_todo(text)
  if error
    session[:error] = error
    erb :list, layout: :layout
  else
    @storage.add_todo(@list_id, text)
    session[:success] = "Todo has successfully been added."
    redirect "/lists/#{@list_id}"
  end
end

# Complete all todos in a list
post "/lists/:list_id/complete_all" do
  @list_id = params[:list_id].to_i
  @list = load_list(@list_id)
  @storage.complete_all_todos(@list_id)
  session[:success] = "All Todos have been completed."
  redirect "/lists/#{@list_id}"
end

# Check todo from list
post "/lists/:list_id/todos/:id" do
  @list_id = params[:list_id].to_i
  @list = load_list(@list_id)
  todo_id = params[:id].to_i
  is_completed = params[:completed] == "true"
  @storage.update_todo_status(@list_id, todo_id, is_completed)
  session[:success] = "The list has been updated."
  redirect "/lists/#{@list_id}"
end

# Delete a todo from list
post "/lists/:list_id/todos/:id/delete" do
  @list_id = params[:list_id].to_i
  @list = load_list(@list_id)
  todo_id = params[:id].to_i
  @storage.delete_todo(@list_id, todo_id)
  if env["HTTP_X_REQUESTED_WITH"] == "XMLHttpRequest"
    status 204
  else
    session[:success] = "The list has been updated."
    redirect "/lists/#{@list_id}"
  end
end
