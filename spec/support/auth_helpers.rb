module AuthHelpers
  def sign_in(user)
    allow(subject).to receive(:current_user) { user }
    allow(user).to receive(:auth_scope) { BonsaiAssetIndex::Authentication::AUTH_SCOPE }
  end

  def sign_out
    allow(subject).to receive(:current_user) { nil }
  end
end
