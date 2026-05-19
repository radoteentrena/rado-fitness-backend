require "rails_helper"

RSpec.describe User, type: :model do
  describe "callbacks" do
    describe "after_create" do
      it "enqueues a welcome email for the created user" do
        user = nil
        expect { user = create(:user) }
          .to have_enqueued_mail(ClientMailer, :welcome).with(a_kind_of(User))
      end
    end
  end

  describe "omniauthable" do
    it { is_expected.to respond_to(:google_uid=) }
    it { is_expected.to respond_to(:provider=) }

    describe "finding user by google_uid" do
      let!(:user) { create(:user, google_uid: '123456789', provider: 'google_oauth2') }

      it 'finds user by google_uid' do
        expect(User.find_by(google_uid: '123456789')).to eq(user)
      end
    end

    describe "email case-insensitivity with status" do
      let!(:active_user) { create(:user, email: 'test@example.com', status: :active) }

      it 'finds active user regardless of email case' do
        expect(User.find_by(email: 'TEST@EXAMPLE.COM'.downcase, status: :active)).to eq(active_user)
      end

      it 'does not find inactive user by email' do
        inactive_user = create(:user, email: 'inactive@example.com', status: :lead)
        expect(User.find_by(email: 'inactive@example.com', status: :active)).to be_nil
      end
    end
  end
end
