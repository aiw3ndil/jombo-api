class HealthController < ActionController::API
  def home
    render html: <<~HTML.html_safe
      <!doctype html>
      <html>
        <head><meta charset="utf-8"><title>Jombo API</title></head>
        <body style="margin:0;height:100vh;background:#22c55e"></body>
      </html>
    HTML
  end

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
