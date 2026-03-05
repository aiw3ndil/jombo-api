require 'rails_helper'

RSpec.describe "Passwords API", type: :request do
  include AuthenticationHelper
  let!(:user) { create(:user, password: 'old_password', password_confirmation: 'old_password') }

  describe "PATCH /api/v1/users/password" do
    let(:valid_params) do
      {
        current_password: 'old_password',
        password: 'new_password',
        password_confirmation: 'new_password'
      }
    end

    let(:invalid_current_password_params) do
      {
        current_password: 'wrong_password',
        password: 'new_password',
        password_confirmation: 'new_password'
      }
    end

    let(:mismatched_password_params) do
      {
        current_password: 'old_password',
        password: 'new_password',
        password_confirmation: 'different_password'
      }
    end

    context "when authenticated" do
      it "updates the password with valid params" do
        patch "/api/v1/users/password", params: valid_params, headers: auth_headers(user)
        expect(response).to have_http_status(:ok)
        
        user.reload
        expect(user.authenticate('new_password')).to eq(user)
      end

      it "fails with incorrect current password" do
        patch "/api/v1/users/password", params: invalid_current_password_params, headers: auth_headers(user)
        expect(response).to have_http_status(:unprocessable_entity)
        json = JSON.parse(response.body)
        expect(json['error']).to eq("Current password is incorrect")
        
        user.reload
        expect(user.authenticate('old_password')).to eq(user)
      end

      it "fails with mismatched password confirmation" do
        patch "/api/v1/users/password", params: mismatched_password_params, headers: auth_headers(user)
        expect(response).to have_http_status(:unprocessable_entity)
        json = JSON.parse(response.body)
        expect(json['errors']).to include("Password confirmation doesn't match Password")
      end
    end

    context "when unauthenticated" do
      it "returns a 401 Unauthorized status" do
        patch "/api/v1/users/password", params: valid_params
        expect(response).to have_http_status(:unauthorized)
      end
    end
  end
end
