# Registrar el método de entrega de Enkimail si no se registró automáticamente
require 'enkimail'

ActionMailer::Base.add_delivery_method :enkimail, Enkimail::DeliveryMethod
