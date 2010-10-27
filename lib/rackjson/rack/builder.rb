module Rack
  class Builder
    # Setup resource collections without authentication.
    #
    # ===Example
    #   expose_resource :collections => [:notes, :projects], :db => @mongo_db
    #
    def expose_resource options
      @ins << lambda do |app|
        Rack::JSON::Resource.new app, options
      end
    end

    # Setup resource collections with public read access but write access only
    # given to the owner of the document, determened from the session var passed
    # as filter.
    #
    # ===Example
    #   public_resource :collections => [:notes, :projects], :db => @mongo_db, :filters => [:user_id]
    #
    def public_resource options
      @ins << lambda do |app|
        Rack::JSON::Filter.new(
          Rack::JSON::Resource.new(app, options),
          options.merge(:methods => [:post, :put, :delete]))
      end
    end

    # Setup resource collections with no public access.  Read and write access only
    # given to the owner of the document, determened from the session vars passed
    # as filters.
    #
    # ===Example
    #   private_resource :collections => [:notes, :projects], :db => @mongo_db, :filters => [:user_id]
    #
    def private_resource options
      @ins << lambda do |app|
        Rack::JSON::Filter.new(
          Rack::JSON::Resource.new(app, options),
          options.merge(:methods => [:get, :post, :put, :delete]))
      end
    end
  end
end