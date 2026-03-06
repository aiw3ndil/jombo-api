class Api::V1::PasswordsController < ApplicationController
  skip_before_action :authenticate_user!, only: [:forgot, :reset], raise: false

  def forgot
    if params[:email].blank?
      return render json: { error: 'Email not present' }, status: :not_found
    end

    user = User.find_by(email: params[:email].downcase)

    if user.present?
      user.generate_password_token!
      UserMailer.password_reset(user).deliver_now
      render json: { status: 'ok', message: 'If your email exists in our database, you will receive a password recovery link at your email address shortly.' }, status: :ok
    else
      # We return :ok even if user not found for security reasons (don't reveal registered emails)
      render json: { status: 'ok', message: 'If your email exists in our database, you will receive a password recovery link at your email address shortly.' }, status: :ok
    end
  end

  def reset
    token = params[:token].to_s

    if params[:token].blank?
      return render json: { error: 'Token not present' }, status: :not_found
    end

    user = User.find_by(reset_password_token: token)

    if user.present? && user.password_token_valid?
      if user.reset_password!(params[:password])
        render json: { status: 'ok', message: 'Password has been reset successfully' }, status: :ok
      else
        render json: { error: user.errors.full_messages }, status: :unprocessable_entity
      end
    else
      render json: { error: 'Link not valid or expired. Try generating a new link.' }, status: :not_found
    end
  end
end
