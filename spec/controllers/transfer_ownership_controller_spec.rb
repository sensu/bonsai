require 'spec_helper'

describe TransferOwnershipController do
  let(:extension) { create(:extension, owner_name: 'FooBar') }

  describe 'PUT #transfer' do
    let(:new_owner) { create(:user) }

    before do
      extension_collection = double('extension_collection', :first! => extension)
      allow(Extension).to receive(:with_name) { extension_collection }
    end

    shared_examples 'admin_or_owner' do
      before do
        sign_in(user)
        extension.collaborator_users << new_owner
      end

      it 'attempts to change the extensions owner' do
        expect_any_instance_of(Extension).to receive(:transfer_ownership).with(
          new_owner
        ) { 'extension.ownership_transfer.done' }
        put :transfer, params: { id: extension.lowercase_name, username: extension.owner_name, extension: { user_id: new_owner.id } }
      end

      it 'redirects back to the extension' do
        put :transfer, params: { id: extension.lowercase_name, username: extension.owner_name, extension: { user_id: new_owner.id } }
        expect(response).to redirect_to [assigns[:extension], username: extension.owner_name]
      end
    end

    context 'the current user is an admin' do
      let(:user) { create(:admin) }
      #it_behaves_like 'admin_or_owner'
    end

    context 'the current user is the extension owner' do
      let(:user) { extension.owner }
      #it_behaves_like 'admin_or_owner'
    end

  end

  context 'transfer requests' do
    let(:transfer_request) { create(:ownership_transfer_request, extension: extension) }

    shared_examples 'a transfer request' do
      it 'redirects back to the extension' do
        pending
        post :accept, params: {token: transfer_request}
        extension = assigns[:transfer_request].extension
        expect(response).to redirect_to [extension, username: extension.owner_name]
      end

      it 'finds transfer requests based on token' do
        pending
        post :accept, params: {token: transfer_request}
        expect(assigns[:transfer_request]).to eql(transfer_request)
      end

      it 'returns a 404 if the transfer request given has already been updated' do
        transfer_request.update_attribute(:accepted, true)
        pending
        post :accept, params: {token: transfer_request}
        expect(response.status.to_i).to eql(404)
      end
    end

    describe 'GET #accept' do
      it 'attempts to accept the transfer request' do
        allow(OwnershipTransferRequest).to receive(:find_by!) { transfer_request }
        expect(transfer_request.accepted).to be_nil
        expect(transfer_request).to receive(:accept!)
        pending
        get :accept, params: {token: transfer_request}
      end

      #it_behaves_like 'a transfer request'
    end

    describe 'GET #decline' do
      it 'attempts to decline the transfer request' do
        allow(OwnershipTransferRequest).to receive(:find_by!) { transfer_request }
        expect(transfer_request.accepted).to be_nil
        expect(transfer_request).to receive(:decline!)
        pending
        get :decline, params: {token: transfer_request}
      end

      #it_behaves_like 'a transfer request'
    end
  end
end
