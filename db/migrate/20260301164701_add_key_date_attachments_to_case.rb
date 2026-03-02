class AddKeyDateAttachmentsToCase < ActiveRecord::Migration[7.2]
  def change
    # No schema changes needed - using Active Storage for attachments
    # The attachment relationships will be defined in the model
  end
end
