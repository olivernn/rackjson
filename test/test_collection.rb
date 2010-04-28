require 'helper'

class CollectionTest < Test::Unit::TestCase
  def setup
    @db = Mongo::Connection.new.db("test")
    @mongo_collection = @db['testing']
    @collection = Rack::JSON::Collection.new(@mongo_collection)
  end

  def teardown
    @collection.delete_all
  end

  test "finding a single document by id" do
    mongo_document = @mongo_collection.save({:testing => true, :rating => 5, :title => 'testing', :_id => 1})
    assert_equal @collection.find(1).attributes, @mongo_collection.find_one(:_id => 1)
    assert_kind_of Rack::JSON::Document, @collection.find(1)
  end

  def test_finding_documents_using_search_conditions
    mongo_document = @mongo_collection.save({:testing => true, :rating => 5, :title => 'testing', :_id => 1})
    mongo_results = []
    @mongo_collection.find(:testing => true).each { |row| mongo_results << row }
    assert_equal @collection.find(:testing => true).first.attributes, mongo_results.first
    assert_kind_of Rack::JSON::Document, @collection.find(:testing => true).first
  end

  def test_finding_documents_using_multiple_search_conditions
    mongo_document = @mongo_collection.save({:testing => true, :rating => 5, :title => 'testing', :_id => 1})
    mongo_results = []
    @mongo_collection.find(:testing => true, :rating => 5).each { |row| mongo_results << row }
    assert_equal @collection.find(:testing => true, :rating => 5).length, mongo_results.length
    assert_equal @collection.find(:testing => true, :rating => 5).first.attributes, mongo_results.first
  end

  def test_finding_no_documents_using_search_conditions
    mongo_document = @mongo_collection.save({:testing => true, :rating => 5, :title => 'testing', :_id => 1})
    assert_equal @collection.find(:testing => false, :rating => 5), []
  end

  def test_finding_documents_with_options
    first_mongo_document = @mongo_collection.save({:testing => true, :rating => 5, :title => 'testing', :_id => 1})
    second_mongo_document = @mongo_collection.save({:testing => true, :rating => 10, :title => 'testing', :_id => 2})
    third_mongo_document = @mongo_collection.save({:testing => false, :rating => 10, :title => 'testing', :_id => 3})
    assert_equal @collection.find({:testing => true}, {:sort => [:rating, :desc]}).length, 2
    assert_equal @collection.find({:testing => true}, {:sort => [:rating, :desc]}).first.attributes["rating"], 10
    assert_equal @collection.find({:testing => true}, {:sort => [:rating, :desc]}).first.attributes["testing"], true
  end

  def test_finding_all_documents_with_options
    first_mongo_document = @mongo_collection.save({:testing => true, :rating => 5, :title => 'testing', :_id => 1})
    second_mongo_document = @mongo_collection.save({:testing => true, :rating => 10, :title => 'testing', :_id => 2})
    assert_equal @collection.all({:sort => [:rating, :desc]}).length, 2
    assert_equal @collection.all({:sort => [:rating, :desc]}).first["rating"], 10
  end

  def test_finding_all_documents
    first_mongo_document = @mongo_collection.save({:testing => true, :rating => 5, :title => 'testing', :_id => 1})
    second_mongo_document = @mongo_collection.save({:testing => true, :rating => 10, :title => 'testing', :_id => 2})
    assert_equal @collection.all.length, 2
  end

  def test_removing_a_document
    first_mongo_document = @mongo_collection.save({:testing => true, :rating => 5, :title => 'testing', :_id => 1})
    second_mongo_document = @mongo_collection.save({:testing => true, :rating => 10, :title => 'testing', :_id => 2})
    assert_equal @collection.all.length, 2
    @collection.delete(1)
    assert_equal @collection.all.length, 1
    assert_equal @collection.all.first["_id"], 2 
  end

  def test_removing_all_documents
    first_mongo_document = @mongo_collection.save({:testing => true, :rating => 5, :title => 'testing', :_id => 1})
    second_mongo_document = @mongo_collection.save({:testing => true, :rating => 10, :title => 'testing', :_id => 2})
    assert_equal @collection.all.length, 2
    @collection.delete
    assert_equal @collection.all.length, 0
  end

  def test_whether_a_document_exists
    first_mongo_document = @mongo_collection.save({:testing => true, :rating => 5, :title => 'testing', :_id => 1})
    assert_equal @collection.all.length, 1
    assert @collection.exists?(1)
    assert !@collection.exists?(2)
  end

  def test_creating_a_document
    assert_equal @collection.all.length, 0
    assert @collection.create({:_id => 1, :title => 'testing'})
    assert_equal @collection.all.length, 1
    assert_equal @collection.find(1).attributes["title"], "testing"
  end

  def test_updating_an_existing_document_by_id
    first_mongo_document = @mongo_collection.save({:testing => true, :rating => 5, :title => 'testing', :_id => 1})
    assert_equal @collection.all.length, 1
    assert @collection.exists?(1)
    assert @collection.update(1, {:testing => false})
    assert_equal @collection.find(1).attributes["testing"], false
  end

  def test_updating_an_existing_document_but_selector_fails
    first_mongo_document = @mongo_collection.save({:testing => true, :rating => 5, :title => 'testing', :_id => 1})
    assert_equal @collection.all.length, 1
    assert @collection.exists?(1)
    assert !@collection.update(1, {:testing => false}, {:rating => 6})
    assert_equal @collection.find(1).attributes["testing"], true
  end
end