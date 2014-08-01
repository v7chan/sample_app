require 'spec_helper'

describe "User pages" do
  subject { page }

  describe "signup page" do
    before { visit signup_path }

    it { should have_title(full_title('Sign up')) }
    it { should have_content('Sign up') }
  end

  describe "profile page" do
    let(:user) { FactoryGirl.create(:user) }
    before { visit user_path(user) }

    it { should have_content(user.name) }
    it { should have_title(user.name) }
  end

  describe "signup" do
    let(:submit) { "Create my account" }
    before { visit signup_path }

    describe "with invalid information" do
      it "should not create a user" do
        expect { click_button submit }.not_to change(User, :count)
      end

      describe "after submission" do
        before { click_button submit }

        it { should have_title('Sign up') }
        it { should have_content('error') }
      end

      describe "with wrong password confirmation after submission" do
        let(:user) { FactoryGirl.build(:user) }
        before do
          invalid_signup(user)
          click_button submit
        end

        it { should have_content("confirmation doesn't match") }
      end
    end

    describe "with valid information" do
      let(:user) { FactoryGirl.build(:user) }
      before { valid_signup(user) }

      it "should create a user" do
        expect { click_button submit }.to change(User, :count)
      end

      describe "after saving the user" do
        before { click_button submit }

        it { should have_link('Sign out') }
        it { should have_title(user.name) }
        it { should have_selector('div.alert.alert-success', text: 'Welcome') }
      end
    end
  end
end