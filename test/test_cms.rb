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
    assert_equal error_message, session[:error]
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
    assert_includes last_response.body, %q(<button type="submit")
  end

  def test_updating_documents
    create_document('changes.txt')

    post '/changes.txt', content: 'new content'
    assert_equal 302, last_response.status
    assert_equal 'changes.txt has been updated.', session[:success]

    get '/changes.txt'
    assert_equal 200, last_response.status
    assert_includes last_response.body, 'new content'
  end

  def test_view_form_new_document
    file_name = 'new_file.txt'
    get "/new"

    assert_equal 200, last_response.status
    assert_includes last_response.body, '<textarea'
    assert_includes last_response.body, %q(<button type="submit")
  end

  def test_creating_new_document
    file_name = 'new_file.txt'

    post '/create', filename: file_name
    assert_equal 302, last_response.status
    assert_equal "#{file_name} has been created", session[:success] 

    get '/'
    assert_includes last_response.body, file_name
  end

  def test_create_new_document_without_filename
    post '/create', filename: ''

    assert_includes last_response.body, 'A name is required'
    assert_equal 422, last_response.status
  end

  def test_deleting_document
    file_name = 'some_document.txt'
    create_document file_name

    post "/#{file_name}/destroy"  
    assert_equal 302, last_response.status
    assert_equal "#{file_name} has been deleted", session[:success]
  end

  def test_deleting_non_existing_document
    file_name = 'some_document.txt'

    post "/#{file_name}/destroy"  
    assert_equal 302, last_response.status
    assert_equal "#{file_name} does not exist", session[:error]
  end

  def test_signin_form
    get '/users/signin'

    assert_equal 200, last_response.status
    assert_includes last_response.body, '<input'
    assert_includes last_response.body, %q(<button type="submit")
  end

  def test_signin
    post '/users/signin', username: 'admin', password: 'secret'
    assert_equal 302, last_response.status
    assert_equal 'admin', session[:username]
    assert_equal 'Welcome!', session[:success]
    
    get last_response['location']
    assert_includes last_response.body, 'Signed in as admin'
  end

  def test_signin_with_bad_credentials
    post '/users/signin', username: 'guest', password: 'shhh'
    assert_equal 422, last_response.status
    assert_equal nil, session[:username]
    assert_includes last_response.body, 'Invalid credentials'
  end

  def test_signout
    post '/users/signout', {}, admin_session
    assert_equal 'You have been signed out.', session[:success]

    get last_response['location']
    assert_includes last_response.body, 'Sign In'
  end

  def setup
    FileUtils.mkdir_p(data_path)
  end

  def teardown
    FileUtils.rm_rf(data_path)
  end

  def session
    last_request.env['rack.session']
  end

  def admin_session
    { 'rack.session' => { username: 'admin' } }
  end
end
