#Sinatra URL shortener.

## Usage

Install the relevent gems (listed below in the Gemfile), and run:

    ruby application.rb

## Deploying

If your server is rack based (Passenger/Heroku), then create the `Gemfile` and
`config.ru` files as detailed below.

## Network

The idea is that users can type `go/mail` in their browser, and be forwarded
to the relevent destination. You can make 'go' resolve in one of two ways.

1. Edit everyone's `/etc/hosts` file

2. Set the 'Search Domains' part of Network Settings. You can do this
   at a company wide level, or on individual machines. These domains are
   searched when resolving urls. For example, you could set a 'Search Domain'
   to be `mycompany.local`, and then create the CNAME `go.mycompany.local`.