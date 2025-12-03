class HealthController < ActionController::API
  def index
    render json: {
      status: 'ok',
      timestamp: Time.current,
      environment: Rails.env,
      version: '1.0.0'
    }
  end
  
  def database
    ActiveRecord::Base.connection.execute('SELECT 1')
    render json: {
      status: 'ok',
      database: 'connected',
      timestamp: Time.current
    }
  rescue => e
    render json: {
      status: 'error',
      database: 'disconnected',
      error: e.message,
      timestamp: Time.current
    }, status: :service_unavailable
  end
end
