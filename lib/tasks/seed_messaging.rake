namespace :seed do
  desc "Seed test conversations and messages for messaging system"
  task messaging: :environment do
    puts "🌱 Seeding messaging test data..."

    # Clear existing test data
    Conversation.where("id > 0").destroy_all

    # Create or find users
    rado = User.find_or_create_by(email: "rado@example.com") do |user|
      user.first_name = "Rado"
      user.last_name = "Coach"
      user.password = "password123"
      user.plan_tier = :high_ticket
    end

    client1 = User.find_or_create_by(email: "juan@example.com") do |user|
      user.first_name = "Juan"
      user.last_name = "Pérez"
      user.password = "password123"
      user.plan_tier = :medium
      user.fcm_token = "test_fcm_token_juan"
    end

    client2 = User.find_or_create_by(email: "maria@example.com") do |user|
      user.first_name = "María"
      user.last_name = "García"
      user.password = "password123"
      user.plan_tier = :high_ticket
      user.fcm_token = "test_fcm_token_maria"
    end

    client3 = User.find_or_create_by(email: "carlos@example.com") do |user|
      user.first_name = "Carlos"
      user.last_name = "Rodriguez"
      user.password = "password123"
      user.plan_tier = :medium
      user.fcm_token = "test_fcm_token_carlos"
    end

    basic_user = User.find_or_create_by(email: "basic@example.com") do |user|
      user.first_name = "Basic"
      user.last_name = "User"
      user.password = "password123"
      user.plan_tier = :basic
    end

    puts "✅ Created/found users: #{[rado.email, client1.email, client2.email, client3.email, basic_user.email].join(', ')}"

    # ===== CONVERSATION 1: JUAN =====
    conv1 = Conversation.create!(
      user_id: client1.id,
      last_message_at: 2.hours.ago,
      read_by_coach_at: 1.hour.ago
    )

    Message.create!(
      conversation_id: conv1.id,
      user_id: client1.id,
      sender_type: :client,
      content: "Hola Rado, tengo una duda sobre los ejercicios de mañana. ¿Cuál es el peso recomendado para el press inclinado?",
      created_at: 2.hours.ago
    )

    Message.create!(
      conversation_id: conv1.id,
      user_id: client1.id,
      sender_type: :coach,
      content: "Dale Juan, para tu nivel te recomiendo 80kg con buena forma. Haz 4 series de 8 reps.",
      read_at: 1.5.hours.ago,
      created_at: 1.5.hours.ago
    )

    Message.create!(
      conversation_id: conv1.id,
      user_id: client1.id,
      sender_type: :client,
      content: "Perfecto, voy a hacerlo así. Gracias!",
      created_at: 1.hour.ago
    )

    Message.create!(
      conversation_id: conv1.id,
      user_id: client1.id,
      sender_type: :coach,
      content: "Excelente. Recuerda controlar la respiración y no sacrificar la forma por el peso. Éxito!",
      read_at: 45.minutes.ago,
      created_at: 45.minutes.ago
    )

    puts "✅ Created conversation 1 (Juan) with 4 messages"

    # ===== CONVERSATION 2: MARÍA WITH VOICE =====
    conv2 = Conversation.create!(
      user_id: client2.id,
      last_message_at: 30.minutes.ago,
      read_by_coach_at: nil
    )

    Message.create!(
      conversation_id: conv2.id,
      user_id: client2.id,
      sender_type: :client,
      content: "¿Qué hago si siento dolor en la espalda durante los sentadillas?",
      created_at: 1.hour.ago
    )

    Message.create!(
      conversation_id: conv2.id,
      user_id: client2.id,
      sender_type: :coach,
      content: "Ese dolor podría ser por falta de calentamiento o mala postura. Déjame enviarte un video con la técnica correcta.",
      created_at: 45.minutes.ago
    )

    # Create voice message
    voice_msg = Message.create!(
      conversation_id: conv2.id,
      user_id: client2.id,
      sender_type: :coach,
      content: nil,
      created_at: 30.minutes.ago
    )

    # Attach dummy voice file
    voice_msg.voice_note.attach(
      io: StringIO.new("simulated webm audio data"),
      filename: "voice_reply_maria.webm",
      content_type: "audio/webm"
    )

    puts "✅ Created conversation 2 (María) with 3 messages (1 voice)"

    # ===== CONVERSATION 3: CARLOS - UNREAD =====
    conv3 = Conversation.create!(
      user_id: client3.id,
      last_message_at: 5.minutes.ago,
      read_by_coach_at: nil
    )

    Message.create!(
      conversation_id: conv3.id,
      user_id: client3.id,
      sender_type: :client,
      content: "¿Puedo cambiar mi rutina? Tengo un viaje la próxima semana.",
      created_at: 10.minutes.ago
    )

    Message.create!(
      conversation_id: conv3.id,
      user_id: client3.id,
      sender_type: :client,
      content: "Vuelvo el 15 de abril, ¿hay algún problema en pausar hasta entonces?",
      created_at: 5.minutes.ago
    )

    puts "✅ Created conversation 3 (Carlos) with 2 unread messages"

    # Display summary
    puts "\n📊 Summary:"
    puts "   - #{User.count} total users"
    puts "   - #{Conversation.count} conversations"
    puts "   - #{Message.count} total messages"
    puts "\n🔐 Test Credentials:"
    puts "   ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    puts "   COACH:"
    puts "   Email:    rado@example.com"
    puts "   Password: password123"
    puts ""
    puts "   CLIENTS:"
    puts "   Juan:     juan@example.com (Medium tier)"
    puts "   María:    maria@example.com (High tier)"
    puts "   Carlos:   carlos@example.com (Medium tier)"
    puts "   Basic:    basic@example.com (Basic tier - no access)"
    puts "   ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    puts "\n🌐 Quick Links:"
    puts "   Admin Panel:      http://localhost:3000/admin/conversations"
    puts "   Admin Login:      rado@example.com / password123"
    puts "\n💡 What to test:"
    puts "   • View 3 conversations in admin panel (different states)"
    puts "   • Open conversations to see read status tracking"
    puts "   • Reply with text message to any conversation"
    puts "   • Try voice recording (click 🎤 button)"
    puts "   • Delete a message (only coach messages can be deleted)"
    puts "   • Log in as client to test mobile API"
    puts "\n✨ Done! Test data created successfully."
  end
end
