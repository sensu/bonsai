require 'spec_helper'

describe OrganizationInvitationsController do
  let(:organization) { create(:organization) }
  let(:user) { create(:user, organizations: [organization]) }
  before { sign_in user }

  describe 'GET #index' do
    context 'user is authorized to view invitations' do
      before do
        auto_authorize!(Organization, 'manage_contributors')
        get :index, params: {organization_id: organization.id}
      end

      it 'tells the view the organization' do
        pending
        expect(assigns[:organization]).to eql(organization)
      end

      describe 'when selecting invitations to send to the view' do
        let!(:pending_invitation) do
          organization.invitations.create!(email: 'chef@example.com')
        end

        let!(:accepted_invitation) do
          organization.invitations.create!(
            email: 'chef@example.com',
            accepted: true
          )
        end

        let!(:declined_invitation) do
          organization.invitations.create!(
            email: 'chef@example.com',
            accepted: false
          )
        end

        it "tells the view the organization's pending invitations" do
          pending
          expect(assigns[:pending_invitations]).to include(pending_invitation)
          expect(assigns[:pending_invitations]).to_not include(accepted_invitation)
          expect(assigns[:pending_invitations]).to_not include(declined_invitation)
        end

        it "tells the view the organization's declined invitations" do
          pending
          expect(assigns[:declined_invitations]).to include(declined_invitation)
          expect(assigns[:declined_invitations]).to_not include(pending_invitation)
          expect(assigns[:declined_invitations]).to_not include(accepted_invitation)
        end
      end

      it "tells the view the organization's contributors" do
        pending
        expect(assigns[:contributors]).to include(user.contributors.first)
      end
    end
  end

  describe 'POST #create' do
    context 'user is authorized to create an Invitation' do
      before { auto_authorize!(Organization, 'manage_contributors') }

      it 'creates the invitation' do
        pending
        expect do
          post :create, params: {
               organization_id: organization.id,
               invitations: { emails: 'chef@example.com' }
          }
        end.to change(organization.invitations, :count).by(1)
      end

      it 'creates multiple invitations' do
        pending
        expect do
          post :create, params: {
               organization_id: organization.id,
               invitations: { emails: 'chef@example.com, chef_2@example.com, chef_3@example.com' }
          }
        end.to change(organization.invitations, :count).by(3)
      end

      it 'sends the invitations' do
        pending
        Sidekiq::Testing.inline! do
          expect do
            post :create, params: {
                 organization_id: organization.id,
                 invitations: { emails: 'chef@example.com, chef_2@example.com' }
            }
          end.to change(ActionMailer::Base.deliveries, :size).by(2)
        end
      end
    end

    context 'an invalid email address is entered' do
      before { auto_authorize!(Organization, 'manage_contributors') }

      it 'creates invitations for the valid email addresses' do
        pending
        expect do
          post :create, params: {
               organization_id: organization.id,
               invitations: { emails: 'chef@example.com, joe, jim, chef_2@example.com' }
          }
        end.to change(organization.invitations, :count).by(2)
      end

      it 'sends invitations to the valid email addresses' do
        pending
        Sidekiq::Testing.inline! do
          expect do
            post :create, params: {
                 organization_id: organization.id,
                 invitations: { emails: 'chef@example.com, joe, jim, chef_2@example.com' }
            }
          end.to change(ActionMailer::Base.deliveries, :size).by(2)
        end
      end

      it 'adds the invalid addresses to a warning flash message' do
        pending
        post :create, params: {
             organization_id: organization.id,
             invitations: { emails: 'chef@example.com, joe, jim, chef_2@example.com' }
        }

        expect(flash['warning']).to match(/joe, jim/)
      end
    end

    context 'user is not authorized to create an Invitation' do
      pending
      it "doesn't create the invitation" do
        expect do
          post :create, params: {
               organization_id: organization.id,
               invitations: { emails: 'chef@example.com' }
          }
        end.to_not change(Invitation, :count)
      end

      it 'responds with 404' do
        pending
        post :create, params: {
             organization_id: organization.id,
             invitations: { emails: 'chef@example.com' }
        }

        should respond_with(404)
      end
    end
  end

  describe 'PATCH #update' do
    let(:invitation) { create(:invitation, admin: true) }

    context 'user is authorized to update an Invitation' do
      before { auto_authorize!(Organization, 'manage_contributors') }

      it 'updates an invitation' do
        pending
        patch :update, params: {
              organization_id: organization.id,
              id: invitation.token,
              invitation: { admin: false }
        }

        invitation.reload

        expect(invitation.admin).to be false
      end
    end

    context 'user is not authorized to update an Invitation' do
      it "doesn't update the invitation" do
        patch :update, params: {
              organization_id: organization.id,
              id: invitation.token,
              invitation: { admin: false }
        }

        invitation.reload

        expect(invitation.admin).to be true
      end

      it 'responds wtih 404' do
        pending
        patch :update, params: {
              organization_id: organization.id,
              id: invitation.token,
              invitation: { admin: false }
        }

        should respond_with(404)
      end
    end
  end

  describe 'PATCH #resend' do
    let(:invitation) { create(:invitation) }
    before { request.env['HTTP_REFERER'] = 'the_previous_path' }

    context 'user is authorized to resend Invitation' do
      before { auto_authorize!(Organization, 'manage_contributors') }

      it 'resends the invitation' do
        pending
        Sidekiq::Testing.inline! do
          expect { patch :resend, params: {organization_id: organization.id, id: invitation.token} }
          .to change(ActionMailer::Base.deliveries, :size).by(1)
        end
      end
    end

    context 'user is not authorized to resend Invitation' do
      it "doesn't resend the invitation" do
        Sidekiq::Testing.inline! do
          expect { patch :resend, params: {organization_id: organization.id, id: invitation.token} }
          .to change(ActionMailer::Base.deliveries, :size).by(0)
        end
      end

      it 'responds with 404' do
        pending
        patch :resend, params: {organization_id: organization.id, id: invitation.token}

        should respond_with(404)
      end
    end
  end

  describe 'DELETE #revoke' do
    let!(:invitation) { create(:invitation) }
    before { request.env['HTTP_REFERER'] = 'the_previous_path' }

    context 'user is authorized to resend Invitation' do
      before { auto_authorize!(Organization, 'manage_contributors') }

      it 'destroys the invitation' do
        pending
        expect { delete :revoke, params: {organization_id: organization.id, id: invitation.token} }
        .to change(Invitation, :count).by(-1)
      end
    end

    context 'user is not authorized to revoke Invitation' do
      it "doesn't revoke the invitation" do
        expect { delete :revoke, params: {organization_id: organization.id, id: invitation.token} }
        .to change(Invitation, :count).by(0)
      end

      it 'responds with 404' do
        pending
        delete :revoke, params: {organization_id: organization.id, id: invitation.token}

        should respond_with(404)
      end
    end
  end
end
