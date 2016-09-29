require 'sinatra'
require 'sinatra/reloader'
require 'tilt/erubis'

DOCS_PATH = 'public/documents'

get '/' do
  @documents = get_documents
  require 'pry'; binding.pry
end

def get_documents
  docs = Dir.entries(DOCS_PATH)
  docs.shift(2) # removes '.' and '..'
  docs
end
