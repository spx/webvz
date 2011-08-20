class UserContainersController < ApplicationController

        before_filter :authorize
        before_filter :get_vps_id
	    before_filter :authorized_logged_in
        before_filter :authorize_client

	def list_vps
		@status = params[:status]
		@user = User.find_by_id(params[:id])
		ids = @user.vpss.map {|vps| [vps.cnt_id]}
                #@status ||= "all"
                if @status == "running"
#this is a bug, filter the running one only
                        i = `vzlist -H #{ids.join(" ")}`
                        k = `vzlist -Hn #{ids.join(" ")}`
                elsif @status == "stopped"
                        i = `vzlist -SH #{ids.join(" ")}`
                        k = `vzlist -SHn #{ids.join(" ")}`
                else
                        i = `vzlist -aH #{ids.join(" ")}`
                        k = `vzlist -aHn #{ids.join(" ")}`
                        @status = ""
                end
		
                @rows = extract_vps_values(i, k)
	end

	def start_vps
                msg = `vzctl start #{@vps_id}`
                redirect_msg(@vps_id, "started\n" + msg)
        end

        def restart_vps
                msg = `vzctl restart #{@vps_id}`
                redirect_msg(@vps_id, "restarted\n" + msg)
        end

        def stop_vps
                msg = `vzctl stop #{@vps_id}`
		redirect_msg(@vps_id, "stopped\n"+ msg)
        end

####### FUBAR

	def backups
		vpses = Vps.find(:all, :conditions => "user_id = '#{params[:id]}'")
		user = User.find(params[:id])
#		@files = []
        files =""
		for vps in vpses
		    files = files + `ls /vz/dump/vzdump-openvz-#{vps.cnt_id}*.tar`
		    files = files + `ls /vz/dump/vzdump-openvz-#{vps.cnt_id}*.tgz`
		end 
		@dumps = []
		for file in files
			@dumps << file.split("/vz/dump/")
		end
	end

    def create_backup
		vpses = Vps.find(:all, :conditions => "user_id = '#{params[:user_id]}'")
#		user = User.find(params[:dump][:user_id])
		msg = `vzdump --compress --maxfiles 2 --suspend #{@vps_id}`
		redirect_msg(@vps_id, "has been backed up\n"+ msg)
	end
		
#	def restore
#		vpses = Vps.find(:all, :conditions => "user_id = '#{params[:dump][:user_id]}'")
#		user = User.find(params[:dump][:user_id])
#		@dump_id = params[:dump_id]
#	end

	def restore_dump
    	vpses = Vps.find(:all, :conditions => "user_id = '#{params[:dump][:user_id]}'")
		user = User.find(params[:dump][:user_id])

		if params[:dump][:id].blank? || params[:dump][:id] == params[:dump_id] 
			flash[:notice] = "The Container ID must be unique"
			@dump_id = params[:dump_id]
			render :action => :restore, :dump_id =>  params[:dump_id]
		elsif params[:dump][:user_id].blank?
			flash[:notice] = "Please assign the container into an owner."
                        @dump_id = params[:dump_id]
                        render :action => :restore, :dump_id =>  params[:dump_id] 
		else
			msg = `vzdump --restore /vz/dump/vzdump-#{params[:dump_id]}.tar #{params[:dump][:id]}`
			vps = Vps.new
			vps.user_id = params[:dump][:user_id]
			vps.cnt_id = params[:dump][:id]
			if vps.save
				flash[:notice] = "Container #{params[:dump_id]} has been restored into #{params[:dump][:id]}"
				redirect_to :action => :list_vps
			else
				flash[:notice] = "Failed to save the owner of the container into database"
				redirect_to :action => :list_vps
			end
		end
	end
	
	def restore
	    vpses = Vps.find(:all, :conditions => "user_id = '#{params[:dump_id][:id]}'")
		user = User.find(params[:id])
		@dump_id = params[:dump_id]
        ctid = @dump_id.split('-')[1]
        msg = `vzctl stop #{ctid}`
        msg = msg + `vzctl destroy #{ctid}`
        msg = msg + `vzrestore /vz/dump/vzdump-#{params[:dump_id]} #{ctid}`
	    flash[:notice] = "Container #{ctid} has been restored\n" + msg
	    redirect_to :action => :list_vps, :id => session[:user_id]
	end
	
	
	
	
	def delete_dump
		user = User.find(params[:id])
        ctid = params[:dump_id].split('-')[1]
   		vpses = Vps.find(:all, :conditions => "user_id = '#{params[:id]}' and cnt_id = '#{ctid}'")
        if vpses.empty?
            flash[:notice] = "You've been a naughty boy! Daddy should spank you!"
        else
            msg = `rm -rf /vz/dump/vzdump-#{params[:dump_id]}`
   	    	flash[:notice] = "vzdump-#{params[:dump_id]} has been deleted successfuly." + msg
        end
        redirect_to :action => :backups, :id => session[:user_id]
	end

	def create_user_backup
	    vpses = Vps.find(:all, :conditions => "user_id = '#{params[:dump][:user_id]}'")
	    user = User.find(params[:dump][:user_id])	
	    unless vpses.size.zero?
		    msg = ""
		    ids = []
		    for vps in vpses
			    msg += `vzdump --suspend #{vps.cnt_id}`
			    ids << vps.cnt_id
		    end
		    flash[:notice] = "#{ids.join(", ")} have been backed up for #{user.name}."
		    redirect_to :action => :backups
	    else
		    flash[:notice] = "#{user.name} has no containers on this server. Nothing was backed up."
		    redirect_to :action => :backup_user_containers	
	    end
    end

	private
	def redirect_msg (vps_id, msg)
                flash[:notice] = "Container #{vps_id} #{msg}"
                redirect_to :action => :list_vps, :id => session[:user_id]
        end

	def authorized_logged_in
		if session[:user_id].to_i != params[:id].to_i
#		    flash[:notice] = ":id --> #{params[:id]}"
#		    flash[:notice] = ":user_id --> #{:user_id}"
			flash[:notice] = "#{params[:id]} #{session[:user_id].to_i} You have no privileges to access other's accounts"
			redirect_to :controller => :menu
		end 
	end



end
