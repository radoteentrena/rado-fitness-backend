# Production Seeds for Rado Fitness

require "json"

WorkoutExercise.delete_all
Workout.delete_all
Exercise.delete_all
Book.delete_all
BookChunk.delete_all

# ============================================================================
# EXERCISES - 42 fitness exercises from programming books
# ============================================================================

exercises = [
  "Press con Mancuerna Inclinada",
  "Remo Sentado",
  "Empuje de Cadera a Una Pierna",
  "Apertura Lateral Lateral con Banda",
  "Empuje de Cadera con Banda en Rodilla",
  "Press con Mancuerna sobre Cabeza",
  "Estocada Inversa con Mancuerna",
  "Jalón Lat",
  "Extensión de Espalda con Mancuerna",
  "Elevación Lateral",
  "Sentadilla Sumo",
  "Press de Banco Agarre Cerrado",
  "Sentadilla Posterior con Pausa",
  "Dominada Negativa",
  "Empuje de Cadera con Barra con Pausa",
  "Abducción de Cadera de Pie con Banda",
  "Extensión de Tríceps sobre Cabeza",
  "Curl de Bícep",
  "Elevación de Pantorrilla de Pie",
  "Elevación Lateral con Mancuerna",
  "Curl Martillo",
  "Curl de Pierna Sentado",
  "Elevación de Pantorrilla Sentado",
  "Press con Mancuerna Declinado",
  "Aperturas en Polea",
  "Remo con Mancuerna",
  "Extensión de Espalda",
  "Prensa de Pierna",
  "Aperturas Traseras Deltoides",
  "Elevación Frontal con Mancuerna",
  "Jalones Faciales en Polea",
  "Curl de Concentración",
  "Empuje de Tríceps en Polea",
  "Salto al Cajón",
  "Empuje de Cadera con Barra",
  "Sentadilla Frontal con Mancuerna",
  "Retroceso en Polea",
  "Elevación Glúteos-Isquio",
  "Press Militar",
  "Sentadilla con Barra",
  "Press de Banco con Barra",
  "Dominada",
  "Peso Muerto Rumano"
]

puts "🏋️  Seeding exercises..."
exercises.each do |exercise_name|
  Exercise.find_or_create_by!(name: exercise_name)
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
