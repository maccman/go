require 'sinatra'
require 'sequel'
require 'sinatra/sequel'
require 'json'

migration 'create links' do
  database.create_table :links do
    primary_key :id
    String :name, :unique => true, :null => false
    String :url, :unique => false, :null => false
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
         Sequel::DatabaseError => e
    halt "Error: #{e.message}"
  end
end

get '/autocomplete' do
  query = params[:q]

  results = Link.filter(:name.like("#{query}%")).or(:url.like("%#{query}%"))
  results = results.all.map {|r| r.name }

  content_type :json
  [query, results].to_json
end

get '/search' do
  query = params[:q]
  link  = Link[:name => query]

  if link
    redirect "/#{link.name}"
  else
    @links = Link.filter(:name.like("#{query}%"))
    erb :index
  end
end

get '/opensearch.xml' do
  content_type :xml
  erb :opensearch, :layout => false
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

      <link rel="search" title="Go" href="opensearch.xml" type="application/opensearchdescription+xml"/>
    </head>
    <body>
      <article><%= yield %></article>
    </body>
  </html>

@@ index
  <form method="post">
    <input type="text" name="name" placeholder="Name" required>
    <input type="url" name="url" placeholder="URL" required>
    <button>Create</button>
  </form>

  <hr />

  <% @links.each do |link| %>
    <li><a href="/<%= link.name %>" title="<%= link.url %>"><%= link.name %></a> (<%= link.hits %>)</li>
  <% end %>

@@ opensearch
  <OpenSearchDescription xmlns="http://a9.com/-/spec/opensearch/1.1/">
    <ShortName>Go</ShortName>
    <Description>Search Go</Description>
    <InputEncoding>UTF-8</InputEncoding>
    <OutputEncoding>UTF-8</OutputEncoding>
    <Url type="application/x-suggestions+json" method="GET" template="http://go/autocomplete">
      <Param name="q" value="{searchTerms}"/>
    </Url>
    <Url type="text/html" method="GET" template="http://go/search">
      <Param name="q" value="{searchTerms}"/>
    </Url>
  </OpenSearchDescription>