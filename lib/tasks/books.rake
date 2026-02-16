namespace :books do
  desc "Ingest a PDF book into the RAG knowledge base"
  task :ingest, [ :file_path, :title, :author ] => :environment do |_t, args|
    unless args[:file_path] && args[:title]
      puts "Usage: rake \"books:ingest[path/to/book.pdf, Book Title, Author Name]\""
      exit 1
    end

    # Check if book already exists
    if (existing_book = Book.find_by(title: args[:title]))
      print "⚠️ Book '#{args[:title]}' already exists. Overwrite? (y/n): "
      input = STDIN.gets.chomp.downcase
      if input == 'y'
        existing_book.destroy!
        puts "🗑  Existing book removed."
      else
        puts "❌ Aborted."
        exit 0
      end
    end

    service = BookIngestionService.new
    begin
      book = service.ingest(args[:file_path], title: args[:title], author: args[:author])
      puts "\n✨ Processed #{book.chunks_count} chunks for '#{book.title}'."
    rescue => e
      puts "\n❌ Error: #{e.message}"
      puts e.backtrace.first(5).join("\n")
    end
  end

  desc "List all ingested books"
  task list: :environment do
    books = Book.all.order(:created_at)

    if books.empty?
      puts "No books ingested yet. Use: rake books:ingest[path,title,author]"
    else
      puts "\n📚 Ingested Books:"
      puts "-" * 60
      books.each do |book|
        puts "  #{book.id}. #{book.title} (#{book.author || 'N/A'}) — #{book.chunks_count} chunks"
      end
      puts "-" * 60
      puts "Total: #{books.count} books, #{BookChunk.count} chunks"
    end
  end

  desc "Remove a book and its chunks"
  task :remove, [ :book_id ] => :environment do |_t, args|
    book = Book.find(args[:book_id])
    title = book.title
    book.destroy!
    puts "🗑  Removed: #{title}"
  rescue ActiveRecord::RecordNotFound
    puts "Book not found with ID: #{args[:book_id]}"
  end
end
