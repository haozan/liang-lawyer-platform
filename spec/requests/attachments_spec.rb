require 'rails_helper'

RSpec.describe "Attachments", type: :request do
  let(:lawyer) { create(:lawyer_account, role: 'super_admin') }  # 使用super_admin跳过权限检查
  let(:company) { create(:company) }
  let(:contract) { create(:contract, company: company) }

  def sign_in_lawyer(lawyer_account)
    post login_path, params: { 
      phone: lawyer_account.phone, 
      password: 'password123',
      user_type: 'lawyer'
    }
  end

  describe "DELETE /attachments/:id" do
    context "when attachment exists and user is authenticated" do
      let(:pdf_file) do
        fixture_file_upload(
          Rails.root.join('spec', 'fixtures', 'files', 'sample.pdf'),
          'application/pdf'
        )
      end

      before do
        sign_in_lawyer(lawyer)
        contract.file.attach(pdf_file)
      end

      it "deletes the attachment successfully" do
        attachment_id = contract.file.id

        expect {
          delete attachment_path(attachment_id), headers: { 'Accept' => 'text/vnd.turbo-stream.html' }
        }.to change(ActiveStorage::Attachment, :count).by(-1)

        expect(response).to have_http_status(:success)
      end

      it "returns turbo_stream response" do
        attachment_id = contract.file.id
        delete attachment_path(attachment_id), headers: { 'Accept' => 'text/vnd.turbo-stream.html' }

        expect(response.media_type).to eq('text/vnd.turbo-stream.html')
      end

      it "removes the attachment from DOM" do
        attachment_id = contract.file.id
        delete attachment_path(attachment_id), headers: { 'Accept' => 'text/vnd.turbo-stream.html' }

        expect(response.body).to include('turbo-stream action="remove"')
        expect(response.body).to include("attachment_#{attachment_id}")
      end
    end

    context "when attachment does not exist" do
      before do
        sign_in_lawyer(lawyer)
      end

      it "returns not found" do
        delete attachment_path(99999), headers: { 'Accept' => 'text/vnd.turbo-stream.html' }
        expect(response).to have_http_status(:not_found)
      end
    end

    context "when user is not authenticated" do
      it "redirects to login" do
        pdf_file = fixture_file_upload(
          Rails.root.join('spec', 'fixtures', 'files', 'sample.pdf'),
          'application/pdf'
        )
        contract.file.attach(pdf_file)
        attachment_id = contract.file.id
        
        delete attachment_path(attachment_id)
        expect(response).to redirect_to(login_path)
      end
    end
  end
end
