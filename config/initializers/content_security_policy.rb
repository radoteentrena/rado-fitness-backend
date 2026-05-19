Rails.application.configure do
  config.content_security_policy do |policy|
    policy.default_src :self
    policy.font_src    :self, :https, :data,
                       "https://api.fontshare.com",
                       "https://fonts.gstatic.com"
    policy.img_src     :self, :https, :data, :blob
    policy.object_src  :none
    policy.script_src  :self, :https, :unsafe_inline
    policy.style_src   :self, :https, :unsafe_inline,
                       "https://api.fontshare.com",
                       "https://fonts.googleapis.com"
    policy.connect_src :self, :https, "wss:"
    policy.frame_src   :self, "https://www.mercadopago.com",
                       "https://www.mercadopago.com.ar"
    policy.frame_ancestors :none
  end
end
