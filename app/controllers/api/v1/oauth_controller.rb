module Api
  module V1
    class OauthController < ApplicationController
      # POST /api/v1/auth/google
      # POST /api/v1/auth/facebook
      def create
        provider = params[:provider]
        token = params[:token]
        
        unless %w[google facebook].include?(provider)
          return render json: { error: 'Invalid provider' }, status: :bad_request
        end
        
        unless token.present?
          return render json: { error: 'Token is required' }, status: :bad_request
        end
        
        # Verify token and get user info
        user_info = verify_oauth_token(provider, token)
        
        if user_info
          user = User.from_omniauth(user_info)
          
          if user.persisted?
            jwt_token = JwtService.encode(user_id: user.id)
            
            cookie_opts = {
              value: jwt_token,
              httponly: true,
              secure: Rails.env.production?,
              same_site: Rails.env.production? ? :none : :lax,
              expires: 2.hours.from_now,
              path: "/"
            }
            
            response.set_cookie("jwt", cookie_opts)
            render json: { 
              message: "Logged in successfully",
              user: {
                id: user.id,
                email: user.email,
                name: user.name,
                language: user.language,
                picture_url: user.picture.attached? ? url_for(user.picture) : nil
              }
            }
          else
            render json: { errors: user.errors.full_messages }, status: :unprocessable_entity
          end
        else
          render json: { error: 'Invalid token' }, status: :unauthorized
        end
      end
      
      private
      
      def verify_oauth_token(provider, token)
        case provider
        when 'google'
          verify_google_token(token)
        when 'facebook'
          verify_facebook_token(token)
        end
      rescue => e
        Rails.logger.error "OAuth verification error: #{e.message}"
        nil
      end
      
      def verify_google_token(token)
        require 'net/http'
        require 'json'
        
        # Try as id_token first
        uri = URI("https://oauth2.googleapis.com/tokeninfo?id_token=#{token}")
        response = Net::HTTP.get_response(uri)
        
        # If id_token fails, try as access_token
        if !response.is_a?(Net::HTTPSuccess)
          uri = URI("https://oauth2.googleapis.com/tokeninfo?access_token=#{token}")
          response = Net::HTTP.get_response(uri)
        end
        
        if response.is_a?(Net::HTTPSuccess)
          data = JSON.parse(response.body)
          
          # Verify the token is for our app
          client_id = ENV['GOOGLE_CLIENT_ID']
          if client_id && data['aud'] && data['aud'] != client_id
            Rails.logger.error "Google token aud mismatch"
            return nil
          end
          
          # If we have token info but need user info, fetch it
          if data['sub'] && !data['email']
            user_uri = URI("https://www.googleapis.com/oauth2/v3/userinfo?access_token=#{token}")
            user_response = Net::HTTP.get_response(user_uri)
            if user_response.is_a?(Net::HTTPSuccess)
              user_data = JSON.parse(user_response.body)
              data['email'] = user_data['email']
              data['name'] = user_data['name']
              data['picture'] = user_data['picture']
            end
          end
          
          OpenStruct.new(
            provider: 'google',
            uid: data['sub'],
            info: OpenStruct.new(
              email: data['email'],
              name: data['name'],
              image: data['picture']
            )
          )
        else
          nil
        end
      end
      
      def verify_facebook_token(token)
        require 'net/http'
        require 'json'
        
        # Verify token with Facebook
        app_id = ENV['FACEBOOK_APP_ID']
        app_secret = ENV['FACEBOOK_APP_SECRET']
        
        if app_id.blank? || app_secret.blank?
          Rails.logger.error "Facebook credentials not configured"
          return nil
        end
        
        # Debug token endpoint
        debug_uri = URI("https://graph.facebook.com/debug_token?input_token=#{token}&access_token=#{app_id}|#{app_secret}")
        debug_response = Net::HTTP.get_response(debug_uri)
        
        unless debug_response.is_a?(Net::HTTPSuccess)
          Rails.logger.error "Facebook token verification failed"
          return nil
        end
        
        debug_data = JSON.parse(debug_response.body)
        
        unless debug_data.dig('data', 'is_valid')
          Rails.logger.error "Facebook token is invalid"
          return nil
        end
        
        # Get user info
        user_uri = URI("https://graph.facebook.com/me?fields=id,name,email,picture&access_token=#{token}")
        user_response = Net::HTTP.get_response(user_uri)
        
        if user_response.is_a?(Net::HTTPSuccess)
          data = JSON.parse(user_response.body)
          
          OpenStruct.new(
            provider: 'facebook',
            uid: data['id'],
            info: OpenStruct.new(
              email: data['email'],
              name: data['name'],
              image: data.dig('picture', 'data', 'url')
            )
          )
        else
          nil
        end
      end
    end
  end
end
