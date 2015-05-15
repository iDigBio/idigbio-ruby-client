require 'minitest/autorun'
require '../lib/client'
require 'mechanize'

class TestClient < Minitest::Test
    def setup
        @client = Idigbio::Client.new
    end

    def test_that_client_can_run_basic_search
        assert @client.search('records/',{rq: {genus: 'acer'}, limit: 100}).key?('itemCount')
    end

    def test_record_search
        assert @client.search_records({genus: 'puma'}).key?('itemCount')
    end

    def test_record_search_with_block
        @client.search_records(rq={'genus' => 'puma'}) do |results|
            assert results.key?('itemCount')
        end
    end

    def test_media_search
        assert @client.search_media({genus: 'puma'})['items'].length >= 1
    end

    def test_view_record
        assert_equal 'd4ccd806-2fe5-49b3-af60-d4f1615a6fab', @client.view_record('d4ccd806-2fe5-49b3-af60-d4f1615a6fab')['uuid']
    end

    def test_view_media
        assert_equal '2a4274aa-fd03-4753-9c69-3805de755516', @client.view_media('2a4274aa-fd03-4753-9c69-3805de755516')['uuid']
    end

    def test_view_recordset
        assert_equal 'c2e06358-1f9f-463c-843f-446c0a37fbd0', @client.view_recordset('c2e06358-1f9f-463c-843f-446c0a37fbd0')['uuid']
    end

    def test_view_publisher
        assert_equal '4e1beef9-d7c0-4ac0-87df-065bc5a55361', @client.view_publisher('4e1beef9-d7c0-4ac0-87df-065bc5a55361')['uuid']
    end

    def test_count_records
        assert @client.count_records({genus: 'puma'}) >= 1 
    end

    def test_count_media
        assert @client.count_media({genus: 'puma'}) >= 1 
    end

    def test_records_last_modified
        assert @client.modified_records({genus: 'acer'}).key? "lastModified" 
    end

    def test_media_last_modified
        assert @client.modified_media({genus: 'acer'}).key? "lastModified"
    end
end