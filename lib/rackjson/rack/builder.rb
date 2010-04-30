module Rack #:nodoc:
  class Builder
    def expose_resource options
      @ins << lambda do |app|
        Rack::JSON::Resource.new app, options
      end
    end

    def public_resource options
      @ins << lambda do |app|
        Rack::JSON::Filter.new(
          Rack::JSON::Resource.new(app, options),
        options.merge(:methods => [:post, :put, :delete]))
      end
    end

    def private_resource options
      @ins << lambda do |app|
        Rack::JSON::Filter.new(
          Rack::JSON::Resource.new(app, options),
        options.merge(:methods => [:get, :post, :put, :delete]))
      end
    end

    # Setup resource collections hosted behind OAuth and OpenID auth filters.
    #
    # ===Example
    #   contain :notes, :projects
    #
    def contain(*args)
      @ins << lambda do |app|
        Rack::Session::Pool.new(
          CloudKit::OAuthFilter.new(
            CloudKit::OpenIDFilter.new(
              CloudKit::Service.new(app, :collections => args.to_a))))
      end
      @last_cloudkit_id = @ins.last.object_id
    end

    # Setup resource collections without authentication.
    #
    # ===Example
    #   expose :notes, :projects
    #
    def expose(*args)
      @ins << lambda do |app|
        CloudKit::Service.new(app, :collections => args.to_a)
      end
      @last_cloudkit_id = @ins.last.object_id
    end

  end
end