ENV["RACK_ENV"] = 'test'

require 'minitest/autorun'
require 'rack/test'
require 'fileutils'

require_relative '../cms'

class CMSTest < Minitest::Test
  include Rack::Test::Methods

  def app
    Sinatra::Application
  end

  def test_index
    create_document 'about.md'
    create_document 'changes.txt'
    
    get '/'
    
    assert_equal 200, last_response.status
    assert_equal 'text/html;charset=utf-8', last_response['Content-Type']
    assert_includes last_response.body, 'about.md'
    assert_includes last_response.body, 'changes.txt'
  end

  def test_viewing_text_document
    create_document('history.txt', 'some text')
  
    get '/history.txt'

    assert_equal 200, last_response.status
    assert_equal 'text/plain', last_response['Content-Type']
    assert_includes last_response.body, 'some text'
  end

  def test_viewing_non_existing_document
    file_name = 'some_document.txt'
    error_message = "#{file_name} does not exist."

    get "/#{file_name}"
    assert_equal 302, last_response.status

    get last_response['location']
    assert_includes last_response.body, error_message

    get '/'
    refute_includes last_response.body, error_message
  end

  def test_viewing_markdown_file
    create_document('about.md', '#Ruby is...')
    converted_title = '<h1>Ruby is...</h1>'

    get '/about.md' 
    assert_equal 200, last_response.status
    assert_equal 'text/html;charset=utf-8', last_response['Content-Type']
    assert_includes last_response.body, converted_title
  end

  def test_editing_documents
    create_document('changes.txt')

    get "/changes.txt/edit"

    assert_equal 200, last_response.status
    assert_includes last_response.body, '<textarea'
    assert_includes last_response.body.strip, %q(<button type="submit")
  end

  def test_updating_documents
    create_document('changes.txt')

    post '/changes.txt', content: 'new content'
    assert_equal 302, last_response.status

    get last_response['location']
    assert_includes last_response.body, 'changes.txt has been updated.'

    get '/changes.txt'
    assert_equal 200, last_response.status
    assert_includes last_response.body, 'new content'
  end

  def setup
    FileUtils.mkdir_p(data_path)
  end

  def teardown
    FileUtils.rm_rf(data_path)
  end

  def create_document(name, content='')
    File.open(file_path(name), 'w') do |file|
      file.write(content)
    end
  end
end
