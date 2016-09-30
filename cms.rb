require 'sinatra'
require 'sinatra/reloader'
require 'tilt/erubis'
require 'redcarpet'

DOCS_PATH = 'data'

configure do
  enable :sessions
end

before do
  @documents = get_documents
end

# Displays links to available documents
get '/' do
  erb :index, layout: :layout
end

# Accesses a document
get '/:document' do
  doc_name = params[:document]

  if @documents.include?(doc_name)
    load_file_content(doc_name)
  else
    session[:error] = "#{doc_name} does not exist."
    redirect '/'
  end
end

def load_file_content(file_name)
  path = "#{DOCS_PATH}/#{file_name}"
  content = File.read(path)

  case File.extname(file_name)
  when '.txt'
    headers['Content-Type'] = 'text/plain'
    content
  when '.md'
    render_markdown(content)
  end
end

# Returns the name of the files in data
def get_documents
  docs = Dir.entries(DOCS_PATH)
  docs.shift(2) # removes '.' and '..'
  docs
end

def render_markdown(content)
  markdown = Redcarpet::Markdown.new(Redcarpet::Render::HTML)
  markdown.render(content)
end
