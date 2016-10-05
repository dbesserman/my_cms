require 'sinatra'
require 'sinatra/reloader'
require 'tilt/erubis'
require 'redcarpet'

DOCS_PATH = 'data'

configure do
  enable :sessions
end

# Displays links to available documents
get '/' do
  @files = files
  erb :index, layout: :layout
end

# gets form to create new document
get '/new' do
  require_sign_in

  erb :new
end

# creates a new document
post '/create' do
  require_sign_in

  file_name = params[:filename]
  content = params[:content]

  if file_name.empty?
    session[:error] = 'A name is required'
    status 422
    erb :new
  elsif file_exists?(file_name)
    session[:error] = "#{file_name} already exists"
    redirect '/'
  else
    create_document(file_name, content)
    session[:success] = "#{file_name} has been created"
    redirect '/'
  end
end

# Accesses a document
get '/:document' do
  file_name = params[:document]

  if file_exists?(file_name)
    load_file_content(file_name)
  else
    session[:error] = "#{file_name} does not exist."
    redirect '/'
  end
end

# Accesses the form to edit a document
get '/:document/edit' do
  require_sign_in

  @file_name = params[:document]
  @content = File.read(file_path(@file_name))

  erb :edit 
end

# updates the document
post '/:document' do
  require_sign_in

  file_name = params[:document]

  if file_exists?(file_name)
    new_content = params[:content]

    File.open(file_path(file_name), 'w') do |f|
      f.write new_content
    end

    session[:success] = "#{file_name} has been updated."
  else
    session[:error] = "#{file_name} does not exist."
  end

  redirect '/'
end

post '/:document/destroy' do
  require_sign_in

  file_name = params[:document]
  
  if file_exists?(file_name)
    FileUtils.remove_file(file_path(file_name))
    session[:success] = "#{file_name} has been deleted"
  else
    session[:error] = "#{file_name} does not exist"
  end

  redirect '/'
end

get '/users/signin' do
  erb :signin
end

post '/users/signin' do
  if params[:username] == 'admin' && params[:password] == 'secret'
    session[:username] = params[:username]
    session[:success] = 'Welcome!'
    redirect '/'
  else
    session[:error] = 'Invalid credentials'
    status 422
    erb :signin
  end
end

post '/users/signout' do
  session.delete(:username)
  session[:success] = 'You have been signed out.'
  redirect '/'
end

#######################################################
## Methods ##
#######################################################

def load_file_content(file_name)
  content = File.read(file_path(file_name))

  case File.extname(file_name)
  when '.txt'
    headers['Content-Type'] = 'text/plain'
    content
  when '.md'
    render_markdown(content)
  end
end

def file_exists?(file_name)
  files.include?(file_name)
end

# Returns the name of the files in data
def files
  docs = Dir.entries(data_path)
  docs.shift(2) # removes '.' and '..'
  docs
end

def render_markdown(content)
  markdown = Redcarpet::Markdown.new(Redcarpet::Render::HTML)
  markdown.render(content)
end

def file_path(file_name)
  "#{data_path}/#{file_name}"  
end

def data_path
  if ENV['RACK_ENV'] == 'test'
    File.expand_path('../test/data', __FILE__)
  else
    File.expand_path('../data', __FILE__)
  end
end

def create_document(name, content='')
  File.open(file_path(name), 'w') do |file|
    file.write(content)
  end
end

def require_sign_in
  unless signed_in?
    session[:error] = 'You must be signed in to do that'
    redirect '/'
  end
end

def signed_in?
  !!session[:username]
end
