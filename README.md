# Sinatra URL shortener

Go is a super simple Sinatra URL shortener for use behind the firewall.

Most companies soon start to build up a fair number of internal URLs, and it can often be tricky remembering these all. This especially difficult when somebody new joins the company.

Go is a simple solution to this problem. Once installed you could point `http://go/wiki`, for example, to your company's internal wiki.

Features:

* Shortens URLs
* OpenSearch integration & autocomplete
* Navigate to 'go' to create/remove shortcuts
* Dynamic parameter substitution
* Hit counts
* Open source

[![Go](http://img.svbtle.com/inline_maccman_24199375604490_raw.png)](https://github.com/maccman/go)

## Usage

    bundle install
    ruby app.rb

## Network

The idea is that users can type `go/mail` in their browser, and be forwarded
to the relevant destination. You can make 'go' resolve in one of two ways.

1. Edit everyone's `/etc/hosts` file

2. Set the 'Search Domains' part of Network Settings (preferred method). You can do this
   at a company wide level, or on individual machines. These domains are
   searched when resolving urls. For example, you could set a 'Search Domain'
   to be `mycompany.local`, and then create the CNAME `go.mycompany.local`.
   Then, 'go' would always resolve to whatever server the CNAME points to.
