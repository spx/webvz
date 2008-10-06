class MenuController < ApplicationController
	def index
	  if session[:permission]
	    redirect_to '/container/list_vps'
    else
      redirect_to '/login/sign_in'
    end
	end	
	def about
	end
end
