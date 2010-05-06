# RackJSON

Simple Rack middleware for persisting JSON documents.

## Installation

`gem install rackjson`

RackJSON uses MongoDB for persistence so you also need to install MongoDB.

## Usage

In your rackup file:

    require mongo
    require rackjson
    
    expose_resource :collections => [:notes], :db => Mongo::Connection.new.db("mydb")
    
    run lambda { |env| 
      [404, {'Content-Length' => '9', 'Content-Type' => 'text/plain'}, "Not Found"]
    }

This will set up a RESTful resource called 'notes' at /notes which will store any JSON document.

### Restricting Access

There are three ways of mounting a restful resource with rackjson:

`expose_resource :collections => [:notes], :db => Mongo::Connection.new.db("mydb")`

Using `expose_resource` won't restrict access to the resource at all, all requests by anyone will succeed.

`public_resource :collections => [:notes], :filters => [:user_id], :db => Mongo::Connection.new.db("mydb")`

Using `public_resource` will allow everyone to perform GET requests against the resource, however to make POST, PUT or DELETE requests the requester must have a specific session param, and will only be able to make requests to documents which match this session param.  In the above example this session param is set to user_id and could be set when logging in.

`public_resource :collections => [:notes], :filters => [:user_id], :db => Mongo::Connection.new.db("mydb")`

Private resource is very similar except that all requests, including GET requests must also satisfy the pre-condition of having a specific session param.

When creating resources with either the public or private resources the specified session param will be included in the document automatically.

### REST API

To see what actions are available on the notes resource:

    curl -i -XOPTIONS http://localhost:9292/notes
    
    HTTP/1.1 200 OK
    Connection: close
    Date: Sun, 11 Apr 2010 11:09:40 GMT
    Content-Type: text/plain
    Content-Length: 0
    Allow: GET, POST

Listing the existing notes:

    curl -i http://localhost:9292/notes
    
    HTTP/1.1 200 OK
    Connection: close
    Date: Sun, 11 Apr 2010 11:12:04 GMT
    Content-Type: application/json
    Content-Length: 2
    
    []

Currently there are no notes, create one with a post request:

    curl -i -XPOST -d'{"title":"hello world!"}' http://localhost:9292/notes
    
    HTTP/1.1 201 Created
    Connection: close
    Date: Sun, 11 Apr 2010 11:14:17 GMT
    Content-Type: application/json
    Content-Length: 149
    
    {"updated_at":"Sun Apr 11 12:14:17 +0100 2010","title":"hello world!","_id":"4bc1af0934701204fd000001","created_at":"Sun Apr 11 12:14:17 +0100 2010"}

RackJSON will assign an id to this resource as _id.  This can be used to access this resource directly

    curl -i http://localhost:9292/notes/4bc1af0934701204fd000001
    
    HTTP/1.1 200 OK
    Connection: close
    Date: Sun, 11 Apr 2010 11:16:30 GMT
    Content-Type: application/json
    Content-Length: 147
    
    [{"updated_at":"Sun Apr 11 11:14:17 UTC 2010","title":"hello world!","_id":"4bc1af0934701204fd000001","created_at":"Sun Apr 11 11:14:17 UTC 2010"}]

This resource will also appear in the index of notes resources

    curl -i http://localhost:9292/notes
    
    HTTP/1.1 200 OK
    Connection: close
    Date: Sun, 11 Apr 2010 11:17:27 GMT
    Content-Type: application/json
    Content-Length: 147
    
    [{"updated_at":"Sun Apr 11 11:14:17 UTC 2010","title":"hello world!","_id":"4bc1af0934701204fd000001","created_at":"Sun Apr 11 11:14:17 UTC 2010"}]

Update a resource using a PUT request

    curl -i -XPUT -d'{"title":"updated"}' http://localhost:9292/notes/4bc1af0934701204fd000001
    
    HTTP/1.1 200 OK
    Connection: close
    Date: Sun, 11 Apr 2010 11:25:04 GMT
    Content-Type: application/json
    Content-Length: 144
    
    {"updated_at":"Sun Apr 11 12:25:04 +0100 2010","title":"updated","_id":"4bc1af0934701204fd000001","created_at":"Sun Apr 11 12:25:04 +0100 2010"}

A PUT request can also be used to create a resource at the given location:

    curl -i -XPUT -d'{"foo":"bar"}' http://localhost:9292/notes/1
    
    HTTP/1.1 200 OK
    Connection: close
    Date: Sun, 11 Apr 2010 11:27:13 GMT
    Content-Type: application/json
    Content-Length: 113
    
    {"updated_at":"Sun Apr 11 12:27:13 +0100 2010","_id":1,"foo":"bar","created_at":"Sun Apr 11 12:27:13 +0100 2010"}

Finally a resource can be deleted using a DELETE request

    curl -i -XDELETE http://localhost:9292/notes/1
    
    HTTP/1.1 200 OK
    Connection: close
    Date: Sun, 11 Apr 2010 11:29:14 GMT
    Content-Type: application/json
    Content-Length: 12
    
    {"ok": "true"}

### JSON Query

RackJSON supports querying of the resources using JSONQuery style syntax.  Pass the JSONQuery as query string parameters when making a get request.

`curl http://localhost:9292/notes?[?title=foo]`

This will get all resources which have a title attribute = 'foo'.  Greater than and less than are also supported:

`curl http://localhost:9292/notes?[?rating>5][?position=<10]`

The resources can be ordered using the query syntax also, to get the notes ordered by rating:

`curl http://localhost:9292/notes?[\rating]`

You can limit the number of resources that are returned, to get the first 10 resources:

`curl http://localhost:9292/notes?[0:10]`

To only select certain properties of a document you can specify the fields you want, to get just the titles

`curl http://localhost:9292/notes?[=title]`
