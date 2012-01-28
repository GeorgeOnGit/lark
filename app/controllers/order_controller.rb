class OrderController < ApplicationController
 layout "lark"
 include HTTParty
 base_uri 'trial.wemakedo.com'

  def index 
  #The content of the cart will be serialized and saved in a memo. Its format is totally up to the user. In this case it is an array of hashes.
   @cart_items = [
            {:song_name=>"the Desert Moon", :id => 1, :price => 12.0, :qty => 3.00},
            {:song_name=>"Hymalayan winds ", :id => 2, :price => 1.0, :qty => 3.0}, 
            {:song_name=>"Pine away", :id => 3, :price => 1.0, :qty => 1.0},
           ]
   session[:cart] = @cart_items.to_json
  end
 # 
  def new
  @order_items = JSON.parse session[:cart]
  #get an single_access_token
  @user_id = 11 
  @api_key = self.class.get("/users/#{@user_id}/rekey.json",  :digest_auth => {:username => "term1", :password => "1234"}) 
  if !@api_key.to_s.include?("Access Denied")
   session[:api_key] = @api_key
  else
   flash[:notice] = @api_key
   redirect_to :back
  end
  end
 # 
  def create
     items = JSON.parse session[:cart]
     sum = items.inject(0.0){ |sum, i| sum + i['price'].to_f * i['qty'].to_f }
     order = {
               :memo => session[:cart], #serialize items and save it to memo field.
               :sum_total => sum,
               :buyer_id => params[:buyer_id] || '4', #buyer's phone number
               :pin => params[:pin] || '1234' #buyer's PIN.
             }
  result = self.class.post("/orders.json", 
                       :body => { :checkout => order, :order_type=> 'checkout', :user_credentials => session[:api_key]})
   if result['status'] == 'success'
   redirect_to(:action => 'show', :id => result['id']) 
   else
   flash[:notice] = result['errors']
   redirect_to(:action => 'index') 
   end
  end
 #  
 def show
  result = self.class.get("/orders/#{params[:id]}.json", :query => { :user_credentials => session[:api_key]})
  if @order = result["order"]
     @payments = result['payments']
     @pay_options = result['pay_options'].collect{| p | [p['ticket'], p['product_id']]  }
  else
   flash[:notice] = result
   redirect_to :action=>'index' 
  end
 end 
 # 
  def trade_in
      payment = { 'order_id' => params[:order_id], 'product_id' => params[:product_id], 'qty' => params[:qty] }
   result = self.class.post("/payments.json", :body=> { :payment => payment, :user_credentials => session[:api_key]})
   if @order = result["order"]
      @payments = result['payments']
      @pay_options = result['pay_options'].collect{| p | [p['ticket'], p['product_id']]  }
   else
    flash[:notice] = result
   end
      respond_to do |format|
      format.html {render :action => 'show'} 
      format.js
      end
  end
 #
  def trade_out
      payment_id = params[:id]
   result = self.class.delete("/payments/#{payment_id}.json", :query => { :user_credentials => session[:api_key]})
   if @order = result["order"]
    @payments = result['payments']
    @pay_options = result['pay_options'].collect{| p | [p['ticket'], p['product_id']]  }
   else
    flash[:notice] = result
   end
   respond_to do |format|
      format.html {render :action => 'show'} 
      format.js
   end
  end
 #
  def update 
  id = params['id'] 
  checkout = { "flat_p_code" => params['flat_p_code']} 
  result = self.class.put("/orders/#{id}.json",
                   :body => {:commit=>params[:commit], :id=>id, :checkout=>checkout , :user_credentials => session[:api_key]})
   if result['status'] == 'success'
   flash[:notice] = "Success! Order #{params[:commit]}."
   redirect_to(:action => 'show', :id => result['id']) 
   else
   flash[:notice] = result["errors"]
   redirect_to(:action => 'show', :id => result['id']) 
   end
  end
 #
end
