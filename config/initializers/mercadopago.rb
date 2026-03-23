# Eagerly require the MercadoPago SDK so that Zeitwerk doesn't interfere
# with the gem's internal constant resolution (Mercadopago::SDK::HttpClient).
require "mercadopago"
