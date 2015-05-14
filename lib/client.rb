require 'mechanize'
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
            @client = Mechanize.new 
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
                    resp = @client.post(@host+path, params.to_json , 'Content-Type' => 'application/json')
                elsif(method.downcase=='get')
                    resp = @client.get(@host+path, params, nil, {'Content-Type' => 'application/json'})
                end

                if block_given?
                    yield JSON.parse resp.body
                else
                    return JSON.parse resp.body
                end
            rescue Mechanize::Error => e
                return {error: e}
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
        # idigbio.search(path: 'records/', params: {rq: {'genus': 'acer'}, offset: 100, limit: 200}) do |results|
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
            orglimit=params[:limit]
            results={}
            out=[]
            more=true
            begin 
                query('search/'+path,params) do |resp|
                    if resp['itemCount'] > 0
                        out.concat resp['items']
                    end
                    if (resp['itemCount'] > out.length && out.length < orglimit && out.length + params[:offset] < resp['itemCount']) || (out.length < resp['itemCount'] && orglimit > resp['itemCount'])
                        params[:offset]+=resp['items'].length
                        params[:limit]-=resp['items'].length
                        more=true
                    else
                        results=resp
                        results['items']=out
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
        # Search iDigBio specimen records with named parameters
        # 
        # @param rq [Hash] see wiki for format
        # @param limit [Fixnum] defaults to 100000 
        # @param offset [Fixnum] 
        # @param fields [Array] field names to return in records. If empty then all fields are returned
        # @param fields_exclude [Array] fields to exclude from records
        # @param sort [Array] should contain hashes in the format of {'fieldName': 'sortDirection'}
        # @return media search results in JSON format
        #
        # results = idigbio.search_records(rq: {genus: 'acer'}, limit: 200)  
        #
        # OR
        #
        # idigbio.search_records(rq: {genus: 'acer'}, limit: 200) do |results|
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
        # Search iDigBio media records with named parameters
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
        # results = idigbio.search_media(rq: {genus: 'acer'}, limit: 200)  
        #
        # OR
        #
        # idigbio.search_media(rq: {genus: 'acer'}, limit: 200) do |results|
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
        def view_record(uuid='')
            query('view/records/'+uuid,{},'get')
        end
        ##
        # Get a media record with uuid
        #
        # @param uuid [String] the uuid (guid) of a media record to retrieve
        # @return media record in JSON format
        #
        # record = idigbio.view_media('1ef39c60-ccda-4431-8a2e-8eba5203c6b4')
        def view_media(uuid='')
            query('view/mediarecords/'+uuid,{},'get')
        end
        ##
        # Get a recordset record with uuid
        #
        # @param uuid [String] the uuid (guid) of a recordset record to retrieve
        # @return recordset record in JSON format
        #
        # record = idigbio.view_recordset('b3976394-a174-4ceb-8d64-3a435d66bde6')
        def view_recordset(uuid='')
            query('view/recordsets/'+uuid,{},'get')
        end
        ##
        # Get a publisher record with uuid
        #
        # @param uuid [String] the uuid (guid) of a publisher record to retrieve
        # @return publisher record in JSON format
        #
        # record = idigbio.view_publisher('4e1beef9-d7c0-4ac0-87df-065bc5a55361')
        def view_publisher(uuid='')
            query('view/publishers/'+uuid,{},'get')
        end

        def count_records(rq={})
            query('summary/count/records/', {rq: rq})['itemCount']
        end

        def count_media(rq={}, mq={})
            query('summary/count/media/', {rq: rq, mq: mq})['itemCount']
        end

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
=begin
        def modified_records(rq: {})

        end

        def modified_media(rq: {}, mq: {})

        end

        def date_histogram(rq: {}, top_fields: [], count: 10, date_field: '', min_date: '', max_date: '', date_interval: '')

        end

        def stats(t: 'api', recordset: '', min_date: '', max_date: '', date_interval: '')

        end

        def fields(type: 'records')

        end
=end
    end
end