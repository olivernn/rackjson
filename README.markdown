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
      [404, {'Content-Type' => 'text/plain'}, ["Not Found"]]
    }

This will set up a RESTful resource called 'notes' at /notes which will store any JSON document.

### Options

Currently you can choose which HTTP verbs the resource will support using the `:only` and `:except` options.  For example this will expose the notes resource to only get methods:

    expose_resource :collections => [:notes], :db => Mongo::Connection.new.db("mydb"), :only => [:get]

And to allow every kind of method except deletes:

    expose_resource :collections => [:notes], :db => Mongo::Connection.new.db("mydb"), :except => [:delete]

### Restricting Access

There are three ways of mounting a restful resource with rackjson:

`expose_resource :collections => [:notes], :db => Mongo::Connection.new.db("mydb")`

Using `expose_resource` won't restrict access to the resource at all, all requests by anyone will succeed.

`public_resource :collections => [:notes], :filters => [:user_id], :db => Mongo::Connection.new.db("mydb")`

Using `public_resource` will allow everyone to perform GET requests against the resource, however to make POST, PUT or DELETE requests the requester must have a specific session param, and will only be able to make requests to documents which match this session param.  In the above example this session param is set to user_id and could be set when logging in.

`private_resource :collections => [:notes], :filters => [:user_id], :db => Mongo::Connection.new.db("mydb")`

`private_resource` is very similar except that all requests, including GET requests must also satisfy the pre-condition of having a specific session param.

When creating resources with either the public or private resources the specified session param will be included in the document automatically.

### REST API

#### Collections

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
    
    {"updated_at":"Sun Apr 11 11:14:17 UTC 2010","title":"hello world!","_id":"4bc1af0934701204fd000001","created_at":"Sun Apr 11 11:14:17 UTC 2010"}

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

#### Nested Documents

Rack::JSON fully supports nested documents.  Any element within a document can be accessed directly regardless of how deeply it is nested.  For example if the following document exists at the location `/notes/1`

    {
      "_id": 1,
      "title": "Nested Document",
      "author": {
        "name": "Bob",
        "contacts": {
          "email": "bob@mail.com"
        }
      },
      "viewed_by": [1, 5, 12, 87],
      "comments": [{
        "user_id": 1
        "text": "awesome!"
      }]
    }

To get just all the comments we can make a get request to `/notes/1/comments`

    curl -i http://localhost:9292/notes/1/comments
    
    HTTP/1.1 200 OK
    Connection: close
    Date: Sun, 29 Aug 2010 19:43:09 GMT
    Content-Type: application/json
    Content-Length: 33
    
    [{"text":"awesome!","user_id":1}]

We can also get just the first comment by passing in the index of that comment in the array, to get the first comment make a GET request to `/notes/1/comments/0`

    curl -i http://localhost:9292/notes/1/comments/0
    
    HTTP/1.1 200 OK
    Connection: close
    Date: Sun, 29 Aug 2010 19:45:28 GMT
    Content-Type: application/json
    Content-Length: 31
    
    {"text":"awesome!","user_id":1}

If we try and get a comment that doesn't exist in the array a 404 is returned.

    curl -i http://localhost:9292/notes/1/comments/1
    
    HTTP/1.1 404 Not Found
    Connection: close
    Date: Sun, 29 Aug 2010 19:46:46 GMT
    Content-Type: text/plain
    Content-Length: 15
    
    field not found

Any field within the document is accessable in this way, just append the field name or the index of the item within an array to the url.

As well as providing read access to any field within a document Rack::JSON also allows you to modify or remove any field within a document.  To change the value of a field make a PUT request to the fields url and pass the value you want as the body.

Both simple values, numbers and strings, or JSON structures can be set in this way, however if you want to set a field to contain a JSON structure (array or object) you must set the correct content type for the request, application/json.

#### Array Modifiers

Fields within a document that are arrays also support atomic push and pulls for adding and removing items from an array.

To push a new item onto an array we make a post request to _push

    curl -i -XPOST -d'101' http://localhost:9292/notes/1/viewed_by/_push

The above will push the value 101 onto the viewed by array within the note with _id 1.

Similarly an item can be pulled from an array using _pull

    curl -i -XPOST -d'101' http://localhost:9292/notes/1/viewed_by/_pull

This will remove the value 101 from the viewed_by array if it already exists.
To remove or add more than one item from an array we can use either _pull_all or _push_all passing in an array each time.

Arrays within documents can also be treated like sets and only add items that do not currently exists by using the add_to_set command like below

    curl -i -XPOST -d'101' http://localhost:9292/notes/1/viewed_by/_add_to_set

This will only add the value 101 to the viewed_by array if it doesn't already exist.

#### Incrementing & Decrementing

RackJSON provides a simple means of incrementing and decrementing counters within a document, simply make a post request to either _increment or _decrement as shown below

    curl -i -XPOST http://localhost:9292/notes/1/views/_increment
    curl -i -XPOST http://localhost:9292/notes/1/views/_decrement

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
