# frozen_string_literal: true

# Sender25 - Added controller to manipulate blacklists (currently disabled)
class BlacklistsController < ApplicationController

  skip_before_action :login_required, only: [:toggle]
  skip_before_action :verify_authenticity_token

  def toggle
    if request.post?
      if params[:payload].blank?
        render :plain => "Blank"
        return
      end
      File.open("/opt/postal/log/blacklist.log", "a+") do |f|
        f.puts(params[:payload])
      end

      (JSON.parse(params[:payload]) || []).each do |ip|
        File.open("/opt/postal/log/blacklist.log", "a+") do |f|
          f.puts("IP:")
          f.puts(ip)
        end
        if (ip_address = IPAddress.where("ipv4 = ? OR ipv6 = ?", ip['address'], ip['address']).first)
          File.open("/opt/postal/log/blacklist.log", "a+") do |f|
            f.puts("IP encontrado:")
            f.puts(ip_address.blacklist)
          end
          if ip['status'] == "DOWN"
            File.open("/opt/postal/log/blacklist.log", "a+") do |f|
              f.puts("IP DOWN")
            end
            ip_address.blacklist = 1
          else
            File.open("/opt/postal/log/blacklist.log", "a+") do |f|
              f.puts("IP UP")
            end
            ip_address.blacklist = 0
          end
          # ip_address.save!
        end
      end
    end
    # render :plain => "#{JSON.parse(params[:payload])}"

    render :plain => "OK"
  end
end
