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

  describe "payment link token" do
    let(:user) { create(:user) }

    it "is valid after generation and invalid after being consumed" do
      user.generate_payment_token!
      expect(user.payment_token_valid?).to be(true)

      user.consume_payment_token!

      expect(user.payment_link_token).to be_nil
      expect(user.payment_link_expires_at).to be_nil
      expect(user.payment_token_valid?).to be(false)
    end
  end

  describe "avatar validations" do
    let(:user) { create(:user) }

    it "rejects a disallowed content type" do
      user.avatar.attach(
        io: StringIO.new("<svg></svg>"), filename: "x.svg", content_type: "image/svg+xml"
      )
      expect(user).not_to be_valid
      expect(user.errors[:avatar]).to be_present
    end

    it "accepts an allowed image type" do
      user.avatar.attach(
        io: StringIO.new("fake"), filename: "a.png", content_type: "image/png"
      )
      expect(user).to be_valid
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
