include ApplicationHelper

def sign_in(user, options={})
  if options[:no_capybara]
    remember_token = User.new_remember_token
    cookies[:remember_token] = remember_token
    user.update_attribute(:remember_token, User.digest(remember_token))
  else
    visit signin_path
    fill_in "Email",    with: user.email.upcase
    fill_in "Password", with: user.password
    click_button "Sign in"
  end
end

def invalid_signup(user)
  fill_in "Name",         with: user.name
  fill_in "Email",        with: user.email
  fill_in "Password",     with: user.password
  fill_in "Confirm Password", with: "mismatch"
end

def valid_signup(user, options={})
  if options[:no_capybara]
    params = { user: { name: user.name, email: user.email, password: user.password, password_confirmation: user.password_confirmation } }
    post users_path, params
  else
    fill_in "Name",         with: user.name
    fill_in "Email",        with: user.email
    fill_in "Password",     with: user.password
    fill_in "Confirm Password", with: user.password_confirmation
  end
end

RSpec::Matchers.define :have_error_message do |message|
  match do |page|
    expect(page).to have_selector('div.alert.alert-error', text: message)
  end
end