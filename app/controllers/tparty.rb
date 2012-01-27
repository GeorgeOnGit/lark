#!/usr/local/bin/ruby   
require 'rubygems'
require 'json'
require 'httparty'

class Thirdrock 
 include HTTParty
 base_uri 'localhost:3000'

 def initialize 
   @cart_items = [{:song_name=>"Pine away", :id => 3, :price => 1, :qty => 3}]
 end
 # 
 def re_key 
 options = { :digest_auth => {:username => "term1", :password => "1234"} }
 @api_key  = self.class.get('/users/11/rekey.json', options)
 puts @api_key
 end
 #
 #
 def create
 order={:memo => @cart_items.to_json, :order_type => 'checkout', :sum_total => 42.0, :mobile => '9196095443', :pin => '1234'}
  result = self.class.post("/orders.json", 
                       :body => { :checkout => order, :order_type=> 'checkout', :user_credentials => @api_key})
#  result  = JSON.parse r.body 
  @order_id = result["id"]
  puts "Order_id = #{@order_id}"
 end
 #  
 def show
  result = self.class.get("/orders/#{@order_id}.json", :query => { :user_credentials => @api_key})
  @order = result["order"]
  puts @order['memo']
 end 
 #
 def execute
  puts "Enter buyer_code:"
  p_code = gets.chomp 
  r = self.class.put("/orders/#{@order_id}/execute.json",
                   :body => {:buy_code => p_code , :user_credentials => @api_key})
  puts "execute result= #{r['status']} order_id= #{r['id']}"
 end
end


while true
   p = Thirdrock.new
   p.re_key

   puts "Hit enter to create order:"
   gets
   p.create

   p.show

   p.execute
end
