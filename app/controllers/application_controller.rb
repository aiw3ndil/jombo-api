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

  # Usuario de la sesión si la hay, sin exigir login (para rutas públicas)
  def optional_user
    return @optional_user if defined?(@optional_user)

    payload = JwtService.decode(request.cookies['jwt'].to_s)
    @optional_user = payload && User.find_by(id: payload[:user_id])
  end
end
