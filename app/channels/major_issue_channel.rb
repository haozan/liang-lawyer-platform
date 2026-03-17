class MajorIssueChannel < ApplicationCable::Channel
  def subscribed
    # Stream name follows "major_issue_ID" pattern (e.g., "major_issue_123")
    @stream_name = params[:stream_name]
    reject unless @stream_name
    
    # Validate stream name format
    reject unless @stream_name.match?(/\Amajor_issue_\d+\z/)
    
    # Extract major_issue_id
    @major_issue_id = @stream_name.split('_').last.to_i
    @major_issue = MajorIssue.find_by(id: @major_issue_id)
    reject unless @major_issue
    
    stream_from @stream_name
  rescue StandardError => e
    handle_channel_error(e)
    reject
  end

  def unsubscribed
    # Any cleanup needed when channel is unsubscribed
  rescue StandardError => e
    handle_channel_error(e)
  end

  # 📨 CRITICAL: ALL broadcasts MUST have 'type' field (auto-routes to handleType method)
  #
  # EXAMPLE: Send new message
  # def send_message(data)
  #   message = Message.create!(content: data['content'])
  #
  #   ActionCable.server.broadcast(
  #     @stream_name,
  #     {
  #       type: 'new-message',  # REQUIRED: routes to handleNewMessage() in frontend
  #       id: message.id,
  #       content: message.content,
  #       user_name: message.user.name,
  #       created_at: message.created_at
  #     }
  #   )
  # end

  # 打字提示
  def typing(data)
    ActionCable.server.broadcast(
      @stream_name,
      {
        type: 'user_typing',
        user_name: data['user_name'],
        user_role: data['user_role']
      }
    )
  end
  
  # 停止打字
  def stop_typing(data)
    ActionCable.server.broadcast(
      @stream_name,
      {
        type: 'user_stop_typing',
        user_name: data['user_name']
      }
    )
  end

  private

  # def current_user
  #   @current_user ||= connection.current_user
  # end
end
