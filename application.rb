require 'rubygems'
require 'sinatra'
require 'sequel'
require 'sinatra/sequel'

migration 'create links' do
  database.create_table :links do
    primary_key :id
    String :name, :unique => true, :null => false
    String :url, :unique => true, :null => false
    Integer :hits, :default => 0
    DateTime :created_at
    index :name
  end
end

class Link < Sequel::Model
  def hit!
    self.hits += 1
    self.save(:validate => false)
  end

  def validate
    super
    errors.add(:name, 'cannot be empty') if !name || name.empty?
    errors.add(:url, 'cannot be empty') if !url || url.empty?
  end
end

get '/' do
  @links = Link.order(:hits.desc).all
  erb :index
end

post '/' do
  begin
    Link.create(
      :name => params[:name],
      :url  => params[:url]
    )
    redirect '/'
  rescue Sequel::ValidationFailed,
         Sequel::DatabaseError
    halt 'Validation failed'
  end
end

get '/:name' do
  link = Link[:name => params[:name]]
  halt 404 unless link
  link.hit!
  redirect link.url
end

__END__

@@ layout
  <!DOCTYPE html>
  <html>
    <head>
      <style type="text/css">
        body {
          font: 13px 'Helvetica Neue',Helvetica,Arial Geneva,sans-serif;
        }

        a, a:link, a:visited, a:active {
          color: #000;
          text-decoration: none;
          border-bottom: 1px solid #CCC;
        }

        article {
          display: inline-block;
          padding: 10px;
          margin: 10px;
          border: 5px solid #000;
        }

        li {
          list-style: none;
          margin-bottom: 5px;
        }

        hr {
          background: 0;
          border: 0;
          border-bottom: 1px solid #CCC;
          margin: 10px 0;
        }

        button {
          height: 21px;
        }

        input {
          width: 100px;
          padding: 3px;
          border: 1px solid rgba(0, 0, 0, 0.20);
          box-shadow: inset 0 1px 2px rgba(0, 0, 0, 0.12);
        }

        input:focus {
          outline: none;
          border-color: rgba(51, 153, 204, 0.5);
          box-shadow: inset 0 1px 2px rgba(0, 0, 0, 0.20), 0 1px 5px 0 rgba(51, 153, 204, 0.4);
        }
      </style>
    </head>
    <body>
      <article><%= yield %></article>
    </body>
  </html>

@@ index
  <% @links.each do |link| %>
    <li><a href="/<%= link.name %>"><%= link.name %></a> (<%= link.hits %>)</li>
  <% end %>

  <hr />

  <form method="post">
    <input type="text" name="name" placeholder="Name">
    <input type="url" name="url" placeholder="URL">
    <button>Create</button>
  </form>