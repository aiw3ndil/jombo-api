class ApplicationController < ActionController::API
  private

  def authenticate_user!
    token = request.cookies['jwt']
    if token
      begin
        decoded_token = JwtService.decode(token)
        @current_user = User.find(decoded_token[:user_id])
      rescue ActiveRecord::RecordNotFound => e
        render json: { error: 'User not found' }, status: :unauthorized
      rescue JWT::DecodeError => e
        render json: { error: 'Invalid token' }, status: :unauthorized
      end
    else
      render json: { error: 'No token provided' }, status: :unauthorized
    end
  end

  def current_user
    @current_user
  end
end
