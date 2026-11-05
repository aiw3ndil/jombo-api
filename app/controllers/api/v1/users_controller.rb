module Api
  module V1
    # Perfil público de un usuario (sin email ni teléfono)
    class UsersController < ApplicationController
      include UserPresenter

      def show
        user = User.find_by(id: params[:id])
        return render json: { error: 'User not found' }, status: :not_found unless user

        upcoming = user.trips.includes(:stops).where(region: User::REGION)
                       .where('departure_time >= ?', Time.current).order(:departure_time).limit(5)
        reviews = user.reviews_received.includes(:reviewer).order(created_at: :desc).limit(5)

        render json: {
          id: user.id,
          name: user.name,
          picture_url: picture_url_for(user),
          bio: user.bio,
          member_since: user.created_at,
          experience_level: user.experience_level,
          average_rating: user.average_rating,
          total_reviews: user.total_reviews,
          trips_driven: user.completed_trips_count,
          rides_taken: user.rides_taken_count,
          verifications: user.verifications,
          upcoming_trips: upcoming.as_json(
            only: [:id, :departure_location, :arrival_location, :departure_time, :price, :available_seats, :instant_booking],
            include: { stops: { only: [:location] } }
          ),
          reviews: reviews.map do |review|
            { id: review.id, rating: review.rating, comment: review.comment, created_at: review.created_at,
              reviewer: { id: review.reviewer_id, name: review.reviewer&.name } }
          end
        }
      end
    end
  end
end
