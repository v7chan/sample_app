require 'spec_helper'

describe "User pages" do
  subject { page }

  describe "index" do
    let(:user) { FactoryGirl.create(:user) }
    before(:each) do
      sign_in user
      visit users_path
    end

    it { should have_title('All users') }
    it { should have_content('All users') }

    describe "pagination" do
      before(:all) { 30.times { FactoryGirl.create(:user) } }
      after(:all) { User.delete_all }

      it { should have_selector('div.pagination') }

      it "should list each user" do
        User.paginate(page: 1).each do |user|
          expect(page).to have_selector('li', text: user.name)
        end
      end
    end

    describe "delete links" do
      it { should_not have_link('delete') }

      describe "as an admin user" do
        let(:admin) { FactoryGirl.create(:admin) }
        before do
          sign_in admin
          visit users_path
        end

        it { should have_link('delete', href: user_path(User.first)) }
        it "should be able to delete another user" do
          expect { click_link('delete', match: :first) }.to change(User, :count).by(-1)
        end
        it { should_not have_link('delete', href: user_path(admin)) }

        describe "trying to delete self" do
          before { sign_in admin, no_capybara: true }

          it "should not delete" do
            expect { delete user_path(admin) }.to_not change(User, :count).by(-1)
          end
        end
      end

      describe "as a non-admin user" do
        let(:user) { FactoryGirl.create(:user) }
        let(:non_admin) { FactoryGirl.create(:user) }

        before { sign_in non_admin, no_capybara: true }

        describe "submitting a DELETE request to the Users#destroy action" do
          before { delete user_path(user) }
          specify { expect(response).to redirect_to(root_url) }
        end
      end
    end
  end

  describe "signup page" do
    before { visit signup_path }

    it { should have_title(full_title('Sign up')) }
    it { should have_content('Sign up') }

    describe "when signed in" do
      let(:user) { FactoryGirl.create(:user) }
      before do 
        sign_in user
        visit signup_path
      end

      it { should_not have_title(full_title('Sign up')) }
      it { should have_content('Welcome') }
    end
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

      describe "when signed in" do
        let(:user) { FactoryGirl.create(:user) }
        let(:new_user) { FactoryGirl.build(:user) }

        before do
          sign_in user, no_capybara: true
          valid_signup new_user, no_capybara: true
        end

        specify { expect(response).to redirect_to(root_url) }
      end
    end
  end

  describe "edit" do
    let(:user) { FactoryGirl.create(:user) }
    before do
      sign_in user
      visit edit_user_path(user)
    end

    describe "page" do
      it { should have_title("Edit User") }
      it { should have_content("Update your profile") }
      it { should have_link('change', href: 'http://gravatar.com/emails') }
    end

    describe "with invalid information" do
      before { click_button "Save changes" }

      it { should have_content('error') }
    end

    describe "with valid information" do
      let(:new_name)  { "New Name" }
      let(:new_email) { "new@example.com" }

      before do
        fill_in "Name",             with: new_name
        fill_in "Email",            with: new_email
        fill_in "Password",         with: user.password
        fill_in "Confirm Password", with: user.password
        click_button "Save changes"
      end

      it { should have_title(new_name) }
      it { should have_selector('div.alert.alert-success') }
      it { should have_link('Sign out', href: signout_path) }
      specify { expect(user.reload.name).to  eq new_name }
      specify { expect(user.reload.email).to eq new_email }
    end

    describe "forbidden attributes" do
      let(:params) do 
        { user: { admin: true, password: user.password, password_confirmation: user.password } }
      end

      before do 
        sign_in user, no_capybara: true
        patch user_path(user), params
      end

      specify { expect(user.reload).not_to be_admin }
    end
  end
end