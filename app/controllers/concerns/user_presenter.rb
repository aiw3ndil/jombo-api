# Datos públicos de un usuario para mostrar en viajes y reservas (nunca email ni teléfono)
module UserPresenter
  extend ActiveSupport::Concern

  private

  # Resumen de confianza: valoración, nivel e insignias. Memoizado por petición,
  # porque un mismo usuario puede aparecer en varios resultados.
  def user_summary(user)
    return nil unless user

    @user_summaries ||= {}
    @user_summaries[user.id] ||= {
      id: user.id,
      name: user.name,
      picture_url: picture_url_for(user),
      average_rating: user.average_rating,
      total_reviews: user.total_reviews,
      experience_level: user.experience_level,
      verifications: user.verifications,
      reliability: user.reliability
    }
  end

  def driver_summary(user)
    user_summary(user)
  end

  def passenger_summary(user)
    user_summary(user)&.merge(rides_taken: user.rides_taken_count)
  end

  def picture_url_for(user)
    return url_for(user.picture) if user.picture.attached?

    user.read_attribute(:picture).presence
  rescue StandardError
    nil
  end
end
