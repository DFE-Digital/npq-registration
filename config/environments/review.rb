require Rails.root.join("config/environments/production")

Rails.application.configure do
  config.after_initialize do
    Bullet.enable                       = true
    Bullet.bullet_logger                = false
    Bullet.raise                        = true # Raise an error if n+1 query occurs
    Bullet.unused_eager_loading_enable  = false # Disabled due to the way our queries are structured
  end

  config.x.teacher_auth.enabled = false
end
