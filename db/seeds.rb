# Production Seeds for Rado Fitness

require "json"

WorkoutExercise.delete_all
Workout.delete_all
# Exercise.delete_all — Commented out to preserve existing exercises in production
# Only new exercises will be created, existing ones will be updated with muscle_group if missing
BookChunk.delete_all
Book.delete_all

# ============================================================================
# EXERCISES - 42 fitness exercises from programming books
# ============================================================================

exercises = [
  { name: "Press con Mancuerna Inclinada", muscle_group: "Chest" },
  { name: "Remo Sentado", muscle_group: "Back" },
  { name: "Empuje de Cadera a Una Pierna", muscle_group: "Glutes" },
  { name: "Apertura Lateral Lateral con Banda", muscle_group: "Chest" },
  { name: "Empuje de Cadera con Banda en Rodilla", muscle_group: "Glutes" },
  { name: "Press con Mancuerna sobre Cabeza", muscle_group: "Shoulders" },
  { name: "Estocada Inversa con Mancuerna", muscle_group: "Legs" },
  { name: "Jalón Lat", muscle_group: "Back" },
  { name: "Extensión de Espalda con Mancuerna", muscle_group: "Back" },
  { name: "Elevación Lateral", muscle_group: "Shoulders" },
  { name: "Sentadilla Sumo", muscle_group: "Legs" },
  { name: "Press de Banco Agarre Cerrado", muscle_group: "Chest" },
  { name: "Sentadilla Posterior con Pausa", muscle_group: "Legs" },
  { name: "Dominada Negativa", muscle_group: "Back" },
  { name: "Empuje de Cadera con Barra con Pausa", muscle_group: "Glutes" },
  { name: "Abducción de Cadera de Pie con Banda", muscle_group: "Glutes" },
  { name: "Extensión de Tríceps sobre Cabeza", muscle_group: "Arms" },
  { name: "Curl de Bícep", muscle_group: "Arms" },
  { name: "Elevación de Pantorrilla de Pie", muscle_group: "Calves" },
  { name: "Elevación Lateral con Mancuerna", muscle_group: "Shoulders" },
  { name: "Curl Martillo", muscle_group: "Arms" },
  { name: "Curl de Pierna Sentado", muscle_group: "Legs" },
  { name: "Elevación de Pantorrilla Sentado", muscle_group: "Calves" },
  { name: "Press con Mancuerna Declinado", muscle_group: "Chest" },
  { name: "Aperturas en Polea", muscle_group: "Chest" },
  { name: "Remo con Mancuerna", muscle_group: "Back" },
  { name: "Extensión de Espalda", muscle_group: "Back" },
  { name: "Prensa de Pierna", muscle_group: "Legs" },
  { name: "Aperturas Traseras Deltoides", muscle_group: "Shoulders" },
  { name: "Elevación Frontal con Mancuerna", muscle_group: "Shoulders" },
  { name: "Jalones Faciales en Polea", muscle_group: "Back" },
  { name: "Curl de Concentración", muscle_group: "Arms" },
  { name: "Empuje de Tríceps en Polea", muscle_group: "Arms" },
  { name: "Salto al Cajón", muscle_group: "Legs" },
  { name: "Empuje de Cadera con Barra", muscle_group: "Glutes" },
  { name: "Sentadilla Frontal con Mancuerna", muscle_group: "Legs" },
  { name: "Retroceso en Polea", muscle_group: "Arms" },
  { name: "Elevación Glúteos-Isquio", muscle_group: "Glutes" },
  { name: "Press Militar", muscle_group: "Shoulders" },
  { name: "Sentadilla con Barra", muscle_group: "Legs" },
  { name: "Press de Banco con Barra", muscle_group: "Chest" },
  { name: "Dominada", muscle_group: "Back" },
  { name: "Peso Muerto Rumano", muscle_group: "Back" }
]

puts "🏋️  Seeding exercises..."
exercises.each do |exercise_data|
  exercise = Exercise.find_or_create_by!(name: exercise_data[:name])
  # Update muscle_group for existing exercises that don't have one
  if exercise.muscle_group.blank?
    exercise.update!(muscle_group: exercise_data[:muscle_group])
    puts "  ✓ Updated #{exercise.name} with muscle group: #{exercise_data[:muscle_group]}"
  end
end
puts "✅ Seeded #{exercises.count} exercises\n"

# ============================================================================
# AI COACH - Books and chunks with embeddings for RAG
# ============================================================================

puts "📚 Loading AI Coach knowledge base..."
books_file = File.join(Rails.root, "db", "books_seed.json")

if File.exist?(books_file)
  books_data = JSON.parse(File.read(books_file))

  books_data.each do |book_data|
    book = Book.find_or_create_by!(title: book_data["title"])
    puts "  📖 #{book.title}"

    # Create chunks with embeddings
    book_data["chunks"].each do |chunk_data|
      book.book_chunks.find_or_create_by!(content: chunk_data["content"]) do |c|
        c.embedding = chunk_data["embedding"]
      end
    end

    puts "    ✓ #{book_data['chunks'].count} chunks loaded"
  end

  puts "✅ AI Coach knowledge base ready (#{Book.count} books, #{BookChunk.count} chunks)\n"
else
  puts "⚠️  db/books_seed.json not found. Skipping book import.\n"
end

puts "🎉 Seeding complete!"
