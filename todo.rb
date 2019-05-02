require 'sinatra'
require 'sinatra/reloader' if development?
require 'sinatra/content_for'
require 'tilt/erubis'
require 'pry'
require 'rack'


configure do
  enable :sessions
  set :session_secret, 'secret'
end

configure do
  set :erb, :escape_html => true
end

# Sets the session before each request
before do
  session[:lists] ||= []
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

    incomplete_lists.each { |list| yield list, lists.index(list) }
    complete_lists.each { |list| yield list, lists.index(list) }
  end

  def sort_todos(todos, &block)
    complete_todos, incomplete_todos = todos.partition { |todo| todo[:completed] }

    incomplete_todos.each { |todo| yield todo, todos.index(todo) }
    complete_todos.each { |todo| yield todo, todos.index(todo) }
  end
end

def load_list(index)
  list = session[:lists][index] if index && session[:lists][index]
  return list if list

  session[:error] = "The specified list does not exist."
  redirect "/lists"
end

# Home page sends to list page
get '/' do
  redirect '/lists'
end

# Renders the list of lists
get '/lists' do
  @lists = session[:lists]
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
  elsif session[:lists].any? { |list| list[:name] == name }
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
    session[:lists] << { name: list_name, todos: [] }
    session[:success] = 'The list has been created.'
    redirect '/lists'
  end
end

# Display a list
get '/lists/:id' do
  @list_id = params[:id].to_i
  @list = load_list(@list_id)
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
  error = error_for_list_name(list_name)

  if error
    session[:error] = error
    erb :edit_list, layout: :layout
  else
    session[:lists][@list_id][:name] = list_name
    session[:success] = 'The list has been successfully renamed.'
    redirect "/lists/#{@list_id}"
  end
end

# Delete a list
post "/lists/:id/delete" do
  @list_id = params[:id].to_i
  @list = load_list(@list_id)
  @list.delete_at(@list_id)
  session[:success] = "The list has been deleted."
  redirect "/lists"
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
    @list[:todos] << {name: params[:todo], completed: false}
    session[:success] = "Todo has successfully been added."
    redirect "/lists/#{@list_id}"
  end
end

# Complete all todos in a list
post "/lists/:list_id/complete_all" do
  @list_id = params[:list_id].to_i
  @list = load_list(@list_id)
  @todos = @list[:todos]
  @todos.each do |todo|
    todo[:completed] = true
  end
  session[:success] = "All Todos have been completed."
  redirect "/lists/#{@list_id}"
end

# Check todo from list
post "/lists/:list_id/todos/:id" do
  @list_id = params[:list_id].to_i
  todo_id = params[:id].to_i
  @list = load_list(@list_id)
  @todos = @list[:todos]
  @todos[todo_id][:completed] = params[:completed] == "true" ? true : false
  session[:success] = "The list has been updated."
  redirect "/lists/#{@list_id}"
end

# Delete a todo from list
post "/lists/:list_id/todos/:id/delete" do
  @list_id = params[:list_id].to_i
  todo_id = params[:id].to_i
  @list = load_list(@list_id)
  @list[:todos].delete_at(todo_id)
  session[:success] = "The list has been updated."
  redirect "/lists/#{@list_id}"
end
