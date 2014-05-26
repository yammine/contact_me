require 'sinatra'
require 'pony'
require 'data_mapper'

DataMapper.setup(:default, ENV["DATABASE_URL"] || "sqlite3://#{Dir.pwd}/contacts.db")

class Contact

  def self.department_lister(dept) ### This is a method to list all of the snippets of a certain category
    @dept_array = []
    self.all.each do |contact|
      @dept_array << contact if contact.department == dept
    end
    @dept_array
  end


  include DataMapper::Resource

  property :id,         Serial

  property :name,       String
  property :address,    Text
  property :department, String
  property :message,    Text

end

DataMapper.finalize

Contact.auto_upgrade!


enable :sessions

helpers do
  def protected!
    return if authorized?
    headers['WWW-Authenticate'] = 'Basic realm="Restricted Area"'
    halt 401, "Not authorized\n"
  end

  def authorized?
    @auth ||=  Rack::Auth::Basic::Request.new(request.env)
    @auth.provided? and @auth.basic? and @auth.credentials and @auth.credentials == ['chris', 'chriscodecore']
  end
end


get '/' do
  erb :contact, layout: :default_layout
end

post '/contact' do

  Contact.create(params)

  @name = params[:name]
  @address = params[:address]
  @department = params[:department]
  @message = params[:message]

  Pony.mail to: 'chris.yammine@hotmail.com',
            from: params[:name],
            subject: "You got an email from #{params[:name]}",
            body: erb(:email),
            headers: { 'Content-Type' => 'text/html' },
            via: :smtp,
            via_options: {
              address: "smtp.gmail.com",
              port: "587",
              enable_starttls_auto: true,
              user_name: "answerawesome",
              password: "Sup3r$ecret",
              authentication: :plain,
              domain: "localhost"
            }

  erb :message, layout: :default_layout

end

get '/list' do
  protected!
  @sales = Contact.department_lister 'Sales'
  @technical = Contact.department_lister 'Technical'
  @marketing = Contact.department_lister 'Marketing'

  erb :list, layout: :default_layout
end











