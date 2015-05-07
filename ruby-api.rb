require 'mechanize'
require 'json'
require 'pry-byebug'
$max_returns = 5000

class Hash 
    #
    #shallow conversion of string keys to sym
    ####
    def symbolize
        self.keys.each{|k| self[k.to_sym] = self.delete(k) }
    end
end

module Idb
    class API
        
        attr_accessor :search, :summary
        
        def initialize
            @host = 'https://beta-search.idigbio.org/v2/'
            @client = Mechanize.new 
        end   
        
        def query path='', params={}, options={method: 'post'}
            begin
                if(options[:method]=='post')
                    resp = @client.post(@host+path, params.to_json , 'Content-Type' => 'application/json')
                elsif(options[:method]=='get')
                    resp = @client.get(@host+path, params.to_json)
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
        
        def search path='records/', params={limit: $max_returns}
            params.symbolize
            limits=[]
            offsets=[]
            offset= (params.key?(:offset) ? params[:offset] : 0)
            results=[]
            limit= (params.key?(:limit) ? params[:limit] : $max_returns)
            total = count_records(params)

            while results.length < total && () 
            if (total > $max_returns || (offset+limit)<total)
                div = (total-offset).divmod($max_returns)
                offsets<<offset
                div[0].times do |i|
                    break if $max_returns*i>total || ($max_returns*(i+1))+offset < total
                    limits << $max_returns 
                    offsets << ($max_returns*(i+1))+offset
                end
                limits<< div[1] > limit ? limit : div[1]
=begin
            elsif !params.key? :limit && total > $max_returns && offset+$max_returns<total
                i=0
                while (i*$max_returns < total) do
                    limits<<$max_returns
                    offsets<<($max_returns*i)+offset
                    i+=1
                end 
=end
            else
                limits<<$max_returns
                offsets<<offset
            end
            binding.pry
            out=[]
            more=false
            begin 
                query('search/'+path,params) do |resp|
                    if resp['itemCount'] > 0
                        out.concat resp['items']
                    end
                end
            end while more
        end

        def search_records params
            search('records/',params)
        end

        def search_media params
            search('media/',params)
        end

        def summary path='', params
            query('summary/'+path,params)
        end

        def count_records params
            query('summary/count/records/', params)['itemCount']
        end

        def view_record uuid
            query(path='view/records/'+uuid,{},{method: 'get'})
        end
    end
end