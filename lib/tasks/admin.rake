namespace :admin do
  desc "Grant super_admin role to a user by email — rails admin:grant_super_admin[email@example.com]"
  task :grant_super_admin, [:email] => :environment do |_, args|
    email = args[:email]
    abort "Usage: rails admin:grant_super_admin[email@example.com]" if email.blank?

    user = User.find_by(email: email)
    abort "User not found: #{email}" unless user

    user.update!(admin_role: :super_admin)
    puts "Granted super_admin to #{user.email}"
  end

  desc "Grant assistant role to a user by email — rails admin:grant_assistant[email@example.com]"
  task :grant_assistant, [:email] => :environment do |_, args|
    email = args[:email]
    abort "Usage: rails admin:grant_assistant[email@example.com]" if email.blank?

    user = User.find_by(email: email)
    abort "User not found: #{email}" unless user

    user.update!(admin_role: :assistant)
    puts "Granted assistant to #{user.email}"
  end

  desc "Revoke admin role from a user by email"
  task :revoke, [:email] => :environment do |_, args|
    email = args[:email]
    abort "Usage: rails admin:revoke[email@example.com]" if email.blank?

    user = User.find_by(email: email)
    abort "User not found: #{email}" unless user

    user.update!(admin_role: nil)
    puts "Revoked admin role from #{user.email}"
  end

  desc "List all users with admin roles"
  task list: :environment do
    users = User.where.not(admin_role: nil).order(:admin_role, :email)
    if users.empty?
      puts "No admin users found. Run: rails admin:grant_super_admin[your@email.com]"
    else
      users.each { |u| puts "#{u.admin_role.ljust(12)} #{u.email}" }
    end
  end
end
