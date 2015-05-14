require 'minitest/autorun'
require '../lib/client'


class TestClient < Minitest::Test
    def setup
        @client = Idigbio::Client.new
    end

    def test_that_client_can_run_basic_search
        assert @client.search('records/', {rq: {genus: 'acer'}, limit: 100}).key?('itemCount')
    end

end