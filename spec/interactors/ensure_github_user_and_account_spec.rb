require "spec_helper"

describe EnsureGithubUserAndAccount do
  let(:github_user) do
    {
      login: "github_account",
      name: "John H. Doe",
      email: "johndoe@example.com"
    }
  end

  subject(:context) { described_class.call(github_user: github_user) }


  describe ".call" do 
    context 'when given the proper parameters' do 
      it "is properly formed and succeeds" do
        expect(described_class.include?(Interactor)).to be_truthy
        expect(context).to be_a_success 
      end
      
      it "provides the proper context" do 
        expect(context.github_user).to eq(github_user)
      end

      it "creates a new account and user" do

        account = context.account 
        user = context.account.user

        expect(user.persisted?).to be(true)
        expect(user.first_name).to eq("John H.")
        expect(user.last_name).to eq("Doe")
        expect(user.email).to eq("johndoe@example.com")

        expect(account.persisted?).to be(true)
        expect(account.username).to eq("github_account")
        expect(account.provider).to eq("github")
      end

      it "does not create a new account if one exists" do
        Account.new(username: "github_account", provider: "github").save(validate: false)
        expect { context  }.not_to change { Account.count }
      end

    end
  end

   
end