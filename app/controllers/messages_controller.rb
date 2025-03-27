# frozen_string_literal: true

class MessagesController < ApplicationController

  include WithinOrganization

  # Sender25 - Added and changed access restrictions
  before_action :admin_required, only: [:plain, :html, :html_raw, :attachment, :attachments, :download]
  before_action { @server = organization.servers.present.find_by_permalink!(params[:server_id]) }
  before_action { params[:id] && @message = @server.message_db.message(params[:id].to_i) }

  def new
    if params[:direction] == "incoming"
      @message = IncomingMessagePrototype.new(@server, request.ip, "web-ui", {})
      @message.from = session[:test_in_from] || current_user.email_tag
      @message.to = @server.routes.order(:name).first&.description
    else
      @message = OutgoingMessagePrototype.new(@server, request.ip, "web-ui", {})
      @message.to = session[:test_out_to] || current_user.email_address
      if domain = @server.domains.verified.order(:name).first
        @message.from = "test@#{domain.name}"
      end
    end
    @message.subject = "Test Message at #{Time.zone.now.to_s(:long)}"
    # Sender25 - Change Postal to Sender25 on the message body
    @message.plain_body = "This is a message to test the delivery of messages through Sender25."
  end

  def create
    if params[:direction] == "incoming"
      session[:test_in_from] = params[:message][:from] if params[:message]
      @message = IncomingMessagePrototype.new(@server, request.ip, "web-ui", params[:message])
      @message.attachments = [{ name: "test.txt", content_type: "text/plain", data: "Hello world!" }]
    else
      session[:test_out_to] = params[:message][:to] if params[:message]
      @message = OutgoingMessagePrototype.new(@server, request.ip, "web-ui", params[:message])
    end
    if result = @message.create_messages
      if result.size == 1
        redirect_to_with_json organization_server_message_path(organization, @server, result.first.last[:id]), notice: "Message was queued successfully"
      else
        redirect_to_with_json [:queue, organization, @server], notice: "Messages queued successfully "
      end
    else
      respond_to do |wants|
        wants.html do
          flash.now[:alert] = "Your message could not be sent. Ensure that all fields are completed fully. #{result.errors.inspect}"
          render "new"
        end
        wants.json do
          render json: { flash: { alert: "Your message could not be sent. Please check all field are completed fully." } }
        end
      end

    end
  end

  def outgoing
    @searchable = true
    get_messages("outgoing")
    respond_to do |wants|
      wants.html
      # Sender25 - Change index to index_outgoing to resolve conflict with incoming
      wants.json do
        render json: {
          flash: flash.each_with_object({}) { |(type, message), hash| hash[type] = message },
          region_html: render_to_string(partial: "index_outgoing", formats: [:html])
        }
      end
    end
  end

  def incoming
    @searchable = true
    get_messages("incoming")
    respond_to do |wants|
      wants.html
      wants.json do
        render json: {
          flash: flash.each_with_object({}) { |(type, message), hash| hash[type] = message },
          region_html: render_to_string(partial: "index", formats: [:html])
        }
      end
    end
  end

  # Sender25 - Added function to resend emails from outgoing search
  def retry_search_outgoing
    retry_search("outgoing")
  end

  # Sender25 - Added function to resend emails from incoming search
  def retry_search_incoming
    retry_search("incoming")
  end

  # Sender25 - Added function to remove emails from outgoing search
  def remove_from_queue_search_outgoing
    remove_from_queue_search("outgoing")
  end

  # Sender25 - Added function to remove emails from incoming search
  def remove_from_queue_search_incoming
    remove_from_queue_search("incoming")
  end

  # Sender25 - Added function to toggle spam from outgoing search
  def toggle_spam_search_outgoing
    toggle_spam_search("outgoing")
  end

  # Sender25 - Added function to toggle spam from incoming search
  def toggle_spam_search_incoming
    toggle_spam_search("incoming")
  end

  def held
    get_messages("held")
  end

  def deliveries
    render json: { html: render_to_string(partial: "deliveries", locals: { message: @message }) }
  end

  def html_raw
    render html: @message.html_body_without_tracking_image.html_safe
  end

  def spam_checks
    @spam_checks = @message.spam_checks.sort_by { |s| s["score"] }.reverse
  end

  def attachment
    if @message.attachments.size > params[:attachment].to_i
      attachment = @message.attachments[params[:attachment].to_i]
      send_data attachment.body, content_type: attachment.mime_type, disposition: "download", filename: attachment.filename
    else
      redirect_to attachments_organization_server_message_path(organization, @server, @message.id), alert: "Attachment not found. Choose an attachment from the list below."
    end
  end

  def download
    if @message.raw_message
      send_data @message.raw_message, filename: "Message-#{organization.permalink}-#{@server.permalink}-#{@message.id}.eml", content_type: "text/plain"
    else
      redirect_to organization_server_message_path(organization, @server, @message.id), alert: "We no longer have the raw message stored for this message."
    end
  end

  def retry
    if @message.raw_message?
      if @message.queued_message
        @message.queued_message.queue!
        flash[:notice] = "This message will be retried shortly."
      elsif @message.held?
        @message.add_to_message_queue(manual: true)
        flash[:notice] = "This message has been released. Delivery will be attempted shortly."
      else
        @message.add_to_message_queue(manual: true)
        flash[:notice] = "This message will be redelivered shortly."
      end
    else
      flash[:alert] = "This message is no longer available."
    end
    redirect_to_with_json organization_server_message_path(organization, @server, @message.id)
  end

  # Sender25 - Added function to toggle spam
  def toggle_spam
    if @message.raw_message? && @message.inspected == 1
      if @message.queued_message && !@message.queued_message.locked?
        @message.queued_message.destroy
      end

      spam_before_status = @message.spam
      result = @message.reinspect_message

      if result
        if @message.spam_score >= @server.outbound_spam_threshold
          @message.update(spam: true)
        else
          @message.update(spam: false)
        end
        @message.update(spam: false) if spam_before_status == 1
      else
        flash[:notice] = "Error when scanning this message."
      end

      if @message.spam == 0 && spam_before_status == 1
        unless @message.queued_message
          @message.add_to_message_queue(manual: true)
          flash[:notice] = "This message will be redelivered shortly."
        end
      elsif result
        flash[:notice] = "Spam score not changed."
      end
    else
      flash[:alert] = "This message is no longer available."
    end
    redirect_to_with_json organization_server_message_path(organization, @server, @message.id)
  end

  def cancel_hold
    @message.cancel_hold
    redirect_to_with_json organization_server_message_path(organization, @server, @message.id)
  end

  def remove_from_queue
    if @message.queued_message && !@message.queued_message.locked?
      @message.queued_message.destroy
    end
    redirect_to_with_json organization_server_message_path(organization, @server, @message.id)
  end

  # Sender25 - Function suppressions moved to org controller
  #def suppressions
  #  @suppressions = @server.message_db.suppression_list.all_with_pagination(params[:page])
  #end

  def activity
    @entries = @message.activity_entries
  end

  private

  # Sender25 - Added function to rescan messages
  def toggle_spam_search(scope)
    get_messages_list(scope)

    @messages.each do |message|
      if message.raw_message? && message.inspected == 1
        if message.queued_message && !message.queued_message.locked?
          message.queued_message.destroy
        end

        spam_before_status = message.spam
        result = message.reinspect_message

        if result
          if message.spam_score >= @server.outbound_spam_threshold
            message.update(spam: 1)
          else
            message.update(spam: 0)
          end
          message.update(spam: 0) if spam_before_status == 1
        else
          flash[:notice] = "Error when scanning this message."
        end

        if message.spam == 0 && spam_before_status == 1
          unless message.queued_message
            message.add_to_message_queue(manual: true)
            flash[:notice] = "This message will be redelivered shortly."
          end
        elsif result
          flash[:notice] = "Spam score not changed."
        end
      else
        flash[:alert] = "This message is no longer available."
      end
    end

    if scope == "outgoing"
      outgoing
    else
      incoming
    end
  end

  # Sender25 - Added function to retry messages
  def retry_search(scope)
    get_messages_list(scope)

    @messages.each do |message|
      if message.raw_message?
        if message.status == "Sent"
          next
        elsif message.queued_message
          message.queued_message.queue!
        elsif message.held?
          message.add_to_message_queue(manual: true)
        else
          message.add_to_message_queue(manual: true)
        end
      end
    end

    if scope == "outgoing"
      outgoing
    else
      incoming
    end
  end

  # Sender25 - Added function to remove emails from search
  def remove_from_queue_search(scope)
    get_messages_list(scope)

    @messages.each do |message|
      if message.queued_message && !message.queued_message.locked?
        message.queued_message.destroy
      end
    end

    if scope == "outgoing"
      outgoing
    else
      incoming
    end
  end

  # Sender25 - Added function to get messages list with scope
  def get_messages_list(scope)
    if scope == "held"
      options = { where: { held: true } }
    else
      options = { where: { scope: scope }, order: :timestamp, direction: "desc" }

      if @query = (params[:query] || session["msg_query_#{@server.id}_#{scope}"]).presence
        session["msg_query_#{@server.id}_#{scope}"] = @query
        qs = Postal::QueryString.new(@query)
        if qs.empty?
          flash.now[:alert] = "It doesn't appear you entered anything to filter on. Please double check your query."
        else
          @queried = true
          if qs[:order] == "oldest-first"
            options[:direction] = "asc"
          end

          if qs[:to] || qs[:notto]
            options[:where][:rcpt_to] = {}
            options[:where][:rcpt_to][:content] = qs[:to] if qs[:to]
            options[:where][:rcpt_to][:not_content] = qs[:notto] if qs[:notto]
          end

          if qs[:from] || qs[:notfrom]
            options[:where][:mail_from] = {}
            options[:where][:mail_from][:content] = qs[:from] if qs[:from]
            options[:where][:mail_from][:not_content] = qs[:notfrom] if qs[:notfrom]
          end

          options[:where][:subject] = qs[:subject] if qs[:subject]
          options[:where][:status] = qs[:status] if qs[:status]
          options[:where][:token] = qs[:token] if qs[:token]

          if qs[:msgid]
            options[:where][:message_id] = qs[:msgid]
            options[:where].delete(:spam)
            options[:where].delete(:scope)
          end
          options[:where][:tag] = qs[:tag] if qs[:tag]
          options[:where][:id] = qs[:id] if qs[:id]
          options[:where][:spam] = true if qs[:spam] == "yes" || qs[:spam] == "y"
          options[:where][:spam] = false if qs[:spam] == "no" || qs[:spam] == "n"
          if qs[:before] || qs[:after]
            options[:where][:timestamp] = {}
            if qs[:before]
              begin
                options[:where][:timestamp][:less_than] = get_time_from_string(qs[:before]).to_f
              rescue TimeUndetermined
                flash.now[:alert] = "Couldn't determine time for before from '#{qs[:before]}'"
              end
            end

            if qs[:after]
              begin
                options[:where][:timestamp][:greater_than] = get_time_from_string(qs[:after]).to_f
              rescue TimeUndetermined
                flash.now[:alert] = "Couldn't determine time for after from '#{qs[:after]}'"
              end
            end
          end
        end
      else
        session["msg_query_#{@server.id}_#{scope}"] = nil
      end
    end

    @messages = @server.message_db.messages(options)
  end

  def get_messages(scope)
    if scope == "held"
      # Sender25 - Added ordering
      options = { where: { held: true }, order: :timestamp, direction: "desc" }
    else
      # Sender25 - Added ordering and remove spam
      options = { where: { scope: scope }, order: :timestamp, direction: "desc" }

      if @query = (params[:query] || session["msg_query_#{@server.id}_#{scope}"]).presence
        session["msg_query_#{@server.id}_#{scope}"] = @query
        qs = Postal::QueryString.new(@query)
        if qs.empty?
          flash.now[:alert] = "It doesn't appear you entered anything to filter on. Please double check your query."
        else
          @queried = true
          if qs[:order] == "oldest-first"
            options[:direction] = "asc"
          end

          # Sender25 - Added new filters for queries
          if qs[:to] || qs[:notto]
            options[:where][:rcpt_to] = {}
            options[:where][:rcpt_to][:content] = qs[:to] if qs[:to]
            options[:where][:rcpt_to][:not_content] = qs[:notto] if qs[:notto]
          end

          # Sender25 - Added new filters for queries
          if qs[:from] || qs[:notfrom]
            options[:where][:mail_from] = {}
            options[:where][:mail_from][:content] = qs[:from] if qs[:from]
            options[:where][:mail_from][:not_content] = qs[:notfrom] if qs[:notfrom]
          end

          # Sender25 - Added new filters for queries
          options[:where][:subject] = qs[:subject] if qs[:subject]

          options[:where][:status] = qs[:status] if qs[:status]
          options[:where][:token] = qs[:token] if qs[:token]

          if qs[:msgid]
            options[:where][:message_id] = qs[:msgid]
            options[:where].delete(:spam)
            options[:where].delete(:scope)
          end
          options[:where][:tag] = qs[:tag] if qs[:tag]
          options[:where][:id] = qs[:id] if qs[:id]
          options[:where][:spam] = true if qs[:spam] == "yes" || qs[:spam] == "y"

          # Sender25 - Added new filters for queries of spam
          options[:where][:spam] = false if qs[:spam] == "no" || qs[:spam] == "n"
          if qs[:before] || qs[:after]
            options[:where][:timestamp] = {}
            if qs[:before]
              begin
                options[:where][:timestamp][:less_than] = get_time_from_string(qs[:before]).to_f
              rescue TimeUndetermined
                flash.now[:alert] = "Couldn't determine time for before from '#{qs[:before]}'"
              end
            end

            if qs[:after]
              begin
                options[:where][:timestamp][:greater_than] = get_time_from_string(qs[:after]).to_f
              rescue TimeUndetermined
                flash.now[:alert] = "Couldn't determine time for after from '#{qs[:after]}'"
              end
            end
          end
        end
      else
        session["msg_query_#{@server.id}_#{scope}"] = nil
      end
    end

    @messages = @server.message_db.messages_with_pagination(params[:page], options)
  end

  class TimeUndetermined < Postal::Error; end

  def get_time_from_string(string)
    begin
      if string =~ /\A(\d{2,4})-(\d{2})-(\d{2}) (\d{2}):(\d{2})\z/
        time = Time.new(::Regexp.last_match(1).to_i, ::Regexp.last_match(2).to_i, ::Regexp.last_match(3).to_i, ::Regexp.last_match(4).to_i, ::Regexp.last_match(5).to_i)
      elsif string =~ /\A(\d{2,4})-(\d{2})-(\d{2})\z/
        time = Time.new(::Regexp.last_match(1).to_i, ::Regexp.last_match(2).to_i, ::Regexp.last_match(3).to_i, 0)
      else
        time = Chronic.parse(string, context: :past)
      end
    rescue StandardError
      time = nil
    end

    raise TimeUndetermined, "Couldn't determine a suitable time from '#{string}'" if time.nil?

    time
  end

end
