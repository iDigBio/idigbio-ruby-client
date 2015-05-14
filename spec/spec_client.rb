require 'minitest/autorun'
require '../lib/client'

describe Idigbio::Client do
    before do 
        @client = Idigbio::Client.new
    end

    describe "searching" do 
        it "fetches many records from the API" do
            @client.search_records({genus: 'puma'}).must_be_instance_of Hash
        end
    end
end