require 'mechanize'
require 'json'
require 'pry-byebug'
$max_limit = 100000

class Hash 
    #
    #shallow conversion of string keys to sym
    ####
    def symbolize
        self.keys.each{|k| self[k.to_sym] = self.delete(k) }
    end
end

module Idigbio
    class Client
        
        def initialize
            @host = 'https://beta-search.idigbio.org/v2/'
            @client = Mechanize.new 
        end   
        
        def query path='', params={}, method='post'
            begin
                if(method=='post')
                    resp = @client.post(@host+path, params.to_json , 'Content-Type' => 'application/json')
                elsif(method=='get')
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
        
        def search(path: 'records/', params: {})
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

        def search_records(rq: {}, limit: $max_limit, offset: 0, fields: [], fields_exclude: [], sort: [])
            params={rq: rq, limit: limit, offset: offset}
            params[:fields]=fields unless fields.empty?
            params[:fields_exclude]=fields_exclude unless fields_exclude.empty? 
            params[:sort]=sort unless sort.empty? 
            search(path: 'records/', params: params)
        end

        def search_media(rq: {}, mq: {}, limit: $max_limit, offset: 0, fields: [], fields_exclude: [], sort: [])
            params={rq: rq, mq: {}, limit: limit, offset: offset}
            params[:fields]=fields unless fields.empty?
            params[:fields_exclude]=fields_exclude unless fields_exclude.empty? 
            params[:sort]=sort unless sort.empty? 
            search(path: 'media/', params: params)
        end

        def summary(path: '', params: {})
            query('summary/'+path,params)
        end

        def count_records params
            query('summary/count/records/', params)['itemCount']
        end

        def view_record(uuid)
            query(path='view/records/'+uuid,{},'get')
        end
    end
end