class MenuController < ApplicationController
  before_filter :authorize, :only => [:index]
	def index
	  logger.debug session.inspect
	  if session.has_key?(:permission) 
      # return redirect_to '/container/list_vps' if is_vz_running
    end
	end	
	
	def about
	end
end
