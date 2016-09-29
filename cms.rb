require 'sinatra'
require 'sinatra/reloader'
require 'tilt/erubis'

DOCS_PATH = 'data'

# Displays links to available documents
get '/' do
  @documents = get_documents
  erb :index, layout: :layout
end

# Accesses a document
get '/:document' do
  doc_name = params[:document]
  headers['Content-Type'] = 'text/plain'

  File.read("#{DOCS_PATH}/#{doc_name}")
end

def get_documents
  docs = Dir.entries(DOCS_PATH)
  docs.shift(2) # removes '.' and '..'
  docs
end
