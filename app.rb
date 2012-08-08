require 'sinatra'
require 'sequel'
require 'sinatra/sequel'
require 'json'

# Models & migrations

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

# Actions

get '/' do
  @links = Link.order(:hits.desc).all
  erb :index
end

get '/links' do
  redirect '/'
end

post '/links' do
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

get '/links/suggest' do
  query = params[:q]

  results = Link.filter(:name.like("#{query}%")).or(:url.like("%#{query}%"))
  results = results.all.map {|r| r.name }

  content_type :json
  [query, results].to_json
end

get '/links/search' do
  query = params[:q]
  link  = Link[:name => query]

  if link
    redirect "/#{link.name}"
  else
    @links = Link.filter(:name.like("#{query}%"))
    erb :index
  end
end

get '/links/opensearch.xml' do
  content_type :xml
  erb :opensearch, :layout => false
end

get '/links/:id/remove' do
  link = Link.find(params[:id])
  halt 404 unless link
  link.destroy
  redirect '/'
end

get '/:name/?*?' do
  link = Link[:name => params[:name]]
  halt 404 unless link
  link.hit!

  parts = (params[:splat].first || '').split('/')

  url = link.url
  url %= parts if parts.any?

  redirect url
end

# Views

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

        a:hover {
          text-decoration: underline;
        }

        article {
          display: inline-block;
          padding: 10px;
          margin: 10px;
          border: 5px solid #000;
        }

        ul {
          margin: 0;
          padding: 0;
        }

        li {
          list-style: none;
          margin-bottom: 5px;
        }

        li section {
          display: inline-block;
          overflow: hidden;
          text-overflow: ellipsis;
          white-space: nowrap;
        }

        .name {
          width: 100px;
        }

        .url {
          width: 150px;
        }

        .actions {
          width: 50px;
          text-align: right;
        }

        .remove {
          display: none;
        }

        .actions:hover .remove {
          display: block;
        }

        .actions:hover .hits {
          display: none;
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

          border: 1px solid #BBB;
          border-top-color: #999;
          box-shadow: inset 0 1px 0 rgba(0, 0, 0, 0.1);
          border-radius: 3px;
        }

        input:focus {
          border: 1px solid #5695DB;
          outline: none;
          -webkit-box-shadow: inset 0 1px 2px #DDD, 0px 0 5px #5695DB;
          -moz-box-shadow: 0 0 5px #5695db;
          box-shadow: inset 0 1px 2px #DDD, 0px 0 5px #5695DB;
        }
      </style>

      <link rel="search" title="Go" href="/links/opensearch.xml" type="application/opensearchdescription+xml"/>
      <title>go</title>
    </head>
    <body>
      <article><%= yield %></article>
    </body>
  </html>

@@ index
  <form method="post" action="/links">
    <input type="text" name="name" placeholder="Name" required>
    <input type="url" name="url" placeholder="URL" required>
    <button>Create</button>
  </form>

  <hr />

  <ul>
    <% @links.each do |link| %>
      <li>
        <section class="name">
          <a href="/<%= link.name %>"><%= link.name %></a>
        </section>

        <section class="url" title="<%= link.url %>"><%= link.url %></section>

        <section class="actions">
          <span class="hits">(<%= link.hits %>)</span>

          <span class="remove">
            <a href="/links/<%= link.id %>/remove" onclick="return confirm('Are you sure?');" title="remove">X</a>
          </span>
        </section>
      </li>
    <% end %>
  </ul>

  <% if @links.empty? %><p>No results</p><% end %>

@@ opensearch
  <OpenSearchDescription xmlns="http://a9.com/-/spec/opensearch/1.1/">
    <ShortName>Go</ShortName>
    <Description>Search Go</Description>
    <InputEncoding>UTF-8</InputEncoding>
    <OutputEncoding>UTF-8</OutputEncoding>
    <Url type="application/x-suggestions+json" method="GET" template="http://go/links/suggest">
      <Param name="q" value="{searchTerms}"/>
    </Url>
    <Url type="text/html" method="GET" template="http://go/links/search">
      <Param name="q" value="{searchTerms}"/>
    </Url>
  </OpenSearchDescription>