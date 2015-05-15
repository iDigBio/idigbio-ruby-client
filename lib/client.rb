#require 'mechanize'
require 'httparty'
require 'json'
#require 'pry-byebug'
$max_limit = 100000

class Hash
    def symbolize
        self.keys.each{|k| self[k.to_sym]=self.delete k}
    end
end

module Idigbio
    class Client
        
        def initialize
            @host = 'https://beta-search.idigbio.org/v2/'
            #@client = Mechanize.new 
        end   
        
        private
        ##
        # Executes a query against the iDigBio API using positional params
        # @param path [String] path to API endpoint
        # @param params [Hash] of parameters to be passed to API (converted to JSON for POST queries)
        # @param method [String] HTTP method to use ('get' or 'post'[default])
        #
        def query(path='', params={}, method='post')
            begin
                if(method.downcase=='post')
                    #resp = @client.post(@host+path, params.to_json, 'Content-Type' => 'application/json')
                    resp = HTTParty.post(@host+path, {:body => params.to_json,:headers => {'Content-Type' => 'application/json'}})
                elsif(method.downcase=='get')
                    #resp = @client.get(@host+path, params, nil, {'Content-Type' => 'application/json'})
                    resp = HTTParty.get(@host+path,{:query => params, :headers => {'Content-Type' => 'application/json'}})
                end

                if block_given?
                    yield JSON.parse resp.body
                else
                    return JSON.parse resp.body
                end
            rescue HTTParty::Error => e
                puts e
                raise 
            end
        end 

        public
        ##
        # Performs basic search against iDigBio API.    
        #
        # @param path [String] the index to search 'records/' or 'media/'
        # @param params [Hash] the parameters for the given search as documents in the API wiki
        # @return [Hash] the search results in JSON format 
        #
        # idigbio = Idigbio::Client.new
        # idigbio.search('records/', {rq: {'genus': 'acer'}, offset: 100, limit: 200}) do |results|
        #     puts results['itemCount']
        # end
        #
        # results = idigbio.search(path:'records/', params)
        #
        def search(path='records/', params={})
            params.symbolize
            params[:rq]={} unless params.key? :rq 
            params[:limit]=$max_limit unless params.key? :limit
            params[:offset]=0 unless params.key? :offset
            limit=params[:limit]
            results={}
            items=[]
            more=true
            begin 
                query('search/'+path,params) do |resp|
                    if resp['itemCount'] > 0
                        items.concat resp['items']
                    end
                    if (resp['itemCount'] > items.length && items.length < limit && limit < resp['itemCount'] && params[:offset]+params[:limit]<resp['itemCount']) || (items.length < resp['itemCount'] && limit > resp['itemCount'])
                        params[:offset]+=resp['items'].length
                        params[:limit]-=resp['items'].length
                        more=true
                    else
                        results=resp
                        results['items']=items
                        more=false
                    end
                end
            end while more 

            if block_given?
                yield results
            else
                return results
            end
        end
        ##
        # Search iDigBio specimen records 
        # 
        # @param rq [Hash] see wiki for format
        # @param limit [Fixnum] defaults to 100000 
        # @param offset [Fixnum] 
        # @param fields [Array] field names to return in records. If empty then all fields are returned
        # @param fields_exclude [Array] fields to exclude from records
        # @param sort [Array] should contain hashes in the format of {'fieldName': 'sortDirection'}
        # @return media search results in JSON format
        #
        # results = idigbio.search_records({genus: 'acer'}, 200)  
        #
        # OR
        #
        # idigbio.search_records( {genus: 'acer'}, 200) do |results|
        #    puts results['itemCount']
        # end
        #
        def search_records(rq={}, limit=$max_limit, offset=0, fields=[], fields_exclude=[], sort=[])
            params={rq: rq, limit: limit, offset: offset}
            params[:fields]=fields unless fields.empty?
            params[:fields_exclude]=fields_exclude unless fields_exclude.empty? 
            params[:sort]=sort unless sort.empty? 
            results = search('records/', params)
            if block_given?
                yield results
            else
                return results
            end
        end
        ##
        # Search iDigBio media records 
        #
        # @param rq [Hash] see wiki for format
        # @param mq [Hash] see wiki for format
        # @param limit [Fixnum] defaults to 100000 
        # @param offset [Fixnum] 
        # @param fields [Array] field names to return in records. If empty then all fields are returned
        # @param fields_exclude [Array] fields to exclude from records
        # @param sort [Array] should contain hashes in the format of {'fieldName': 'sortDirection'}
        # @return media search results in JSON format
        #
        # results = idigbio.search_media({genus: 'acer'}, 200)  
        #
        # OR
        #
        # idigbio.search_media({genus: 'acer'}, 200) do |results|
        #    puts results['itemCount']
        # end
        #
        def search_media(rq={}, mq={}, limit=$max_limit, offset=0, fields=[], fields_exclude=[], sort=[])
            params={rq: rq, mq: {}, limit: limit, offset: offset}
            params[:fields]=fields unless fields.empty?
            params[:fields_exclude]=fields_exclude unless fields_exclude.empty? 
            params[:sort]=sort unless sort.empty? 
            results = search('media/', params)
            if block_given?
                yield results
            else
                return results
            end
        end
        ##
        # Get a specimen record with uuid
        #
        # @param uuid [String] the uuid (guid) of a specimen record to retrieve
        # @return specimen record in JSON format
        #
        # record = idigbio.view_record('8a0c0ea9-4b10-44a7-8a0d-ab4e12d9f607')
        #
        def view_record(uuid='')
            query('view/records/'+uuid,{},'get')
        end
        alias_method :get_record, :view_record
        ##
        # Get a media record with uuid
        #
        # @param uuid [String] the uuid (guid) of a media record to retrieve
        # @return media record in JSON format
        #
        # record = idigbio.view_media('1ef39c60-ccda-4431-8a2e-8eba5203c6b4')
        #
        def view_media(uuid='')
            query('view/mediarecords/'+uuid,{},'get')
        end
        alias_method :get_media, :view_media
        ##
        # Get a recordset record with uuid
        #
        # @param uuid [String] the uuid (guid) of a recordset record to retrieve
        # @return recordset record in JSON format
        #
        # record = idigbio.view_recordset('b3976394-a174-4ceb-8d64-3a435d66bde6')
        #
        def view_recordset(uuid='')
            query('view/recordsets/'+uuid,{},'get')
        end
        alias_method :get_recordset, :view_recordset
        ##
        # Get a publisher record with uuid
        #
        # @param uuid [String] the uuid (guid) of a publisher record to retrieve
        # @return publisher record in JSON format
        #
        # record = idigbio.view_publisher('4e1beef9-d7c0-4ac0-87df-065bc5a55361')
        #
        def view_publisher(uuid='')
            query('view/publishers/'+uuid,{},'get')
        end
        alias_method :get_publisher, :view_publisher
        ##
        # Gets total number of records matching rq
        #
        # @param rq [Hash] record query params
        # @return [Fixnum] record count
        #
        def count_records(rq={})
            query('summary/count/records/', {rq: rq})['itemCount']
        end
        ##
        # Gets total number of media records matching rq and mq
        # 
        # @param rq [Hash]
        # @param mq [Hash]
        # @return [Fixnum] media record count
        #
        def count_media(rq={}, mq={})
            query('summary/count/media/', {rq: rq, mq: mq})['itemCount']
        end
        ##
        # 
        def top_records(rq={}, top_fields=[], count=10)
            params={rq: rq, count: count}
            params[:top_fields] = top_fields unless top_fields.empty?
            query('summary/top/records/', params)
        end

        def top_media(rq={}, mq={}, top_fields=[], count=10)
            params={rq: rq, mq: {}, count: count}
            params[:top_fields] = top_fields unless top_fields.empty?
            query('summary/top/media/', params)
        end
        ##
        # Gets last modified date of items matching this query
        # @param rq [Hash] API record query params
        # @return [Hash] with lastModified and itemCount keys for matching query
        #
        def modified_records(rq={})
            query('summary/modified/records/',{rq: rq})
        end
        ##
        # Gets last modified date of items matching this query
        # @param rq [Hash] API record query params
        # @param mq [Hash] API media query params
        # @return [Hash] with lastModified and itemCount keys for matching query
        #
        def modified_media(rq={}, mq={})
            query('summary/modified/media/',{rq: rq, mq: mq})
        end

        def date_histogram(rq={}, top_fields=[], count=10, date_field='', min_date='', max_date='', date_interval='')
            params={}
            query('summary/datehist/',params)
        end

        def stats(t='api', recordset='', min_date='', max_date='', date_interval='')
            params={}
            query('summary/stats/'+t,params)
        end
        ##
        # Get list of field mappings in API
        #
        # @param type [String] index type to get mapping for can be (records[default]|mediarecords|recordsets|publishers)
        # @return [Hash] of field mappings
        #
        def fields(type='records')
            query('meta/fields/'+type)
        end
    end
end