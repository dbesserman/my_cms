require 'sinatra'
require 'sinatra/reloader'
require 'tilt/erubis'

DOCS_PATH = 'data'

get '/' do
  @documents = get_documents
  erb :main, layout: :layout
end

def get_documents
  docs = Dir.entries(DOCS_PATH)
  docs.shift(2) # removes '.' and '..'
  docs
end
