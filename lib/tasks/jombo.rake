namespace :jombo do
  desc 'Tareas periódicas: recordatorios, caducidad de solicitudes y peticiones de valoración'
  task hourly: :environment do
    result = TripLifecycleService.run
    Rails.logger.info("[jombo:hourly] #{result}")
    puts "jombo:hourly #{result}"
  end
end
