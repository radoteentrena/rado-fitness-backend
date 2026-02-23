require "pdf-reader"

class BookIngestionService
  CHUNK_SIZE = 500       # Target tokens per chunk (~2000 chars)
  CHUNK_OVERLAP = 50     # Overlap tokens for context continuity
  CHARS_PER_TOKEN = 4    # Rough estimate for English text

  def initialize
    @embedding_service = EmbeddingService.new
    @gemini_service = GeminiService.new
  end

  # Ingest a PDF book: extract text, chunk, embed, and store
  def ingest(file_path, title:, author: nil)
    raise "File not found: #{file_path}" unless File.exist?(file_path)

    puts "\n📖 Reading: #{title}..."
    book = Book.create!(title: title, author: author, file_path: file_path)

    # Extract text from PDF (with image page handling)
    pages = extract_pages(file_path)
    puts "📄 Extracted #{pages.size} pages."

    # Chunk the text
    print "🔪 Chunking text..."
    chunks = chunk_pages(pages)
    puts " Done. Created #{chunks.size} chunks."

    # Embed and store chunks
    puts "🧠 Generating embeddings (this may take a few minutes)..."
    chunks.each_with_index do |chunk, index|
      print "." if (index % 5).zero?
      embedding = @embedding_service.embed(chunk[:content])

      if embedding
        BookChunk.create!(
          book: book,
          content: chunk[:content],
          page_number: chunk[:page_number],
          chunk_index: index,
          embedding: embedding
        )
      else
        puts "\n⚠️ Failed to embed chunk #{index}, skipping"
      end

      # Small sleep to respect free-tier rate limits if needed
      # sleep(0.1)
    end

    book.reload
    puts "\n✅ Ingestion complete! #{book.chunks_count} chunks stored."
    book
  end

  private

  # Extract text from each page, using Gemini vision for image-heavy pages
  def extract_pages(file_path)
    reader = PDF::Reader.new(file_path)
    pages = []

    reader.pages.each_with_index do |page, index|
      text = page.text.to_s.strip

      if text.length < 50
        # Page has very little text — likely an image/table
        Rails.logger.info("📷 Page #{index + 1} is image-heavy, using Gemini vision...")
        vision_text = extract_with_vision(file_path, index + 1)
        text = vision_text if vision_text.present?
      end

      # Remove null bytes and other invalid characters before storing
      sanitized_text = sanitize_text(text)
      pages << { page_number: index + 1, text: sanitized_text } if sanitized_text.present?
    end

    pages
  end

  def sanitize_text(text)
    return "" if text.blank?
    # Remove null bytes, which PG doesn't support in strings
    # Also remove other non-printable control characters except newlines/tabs
    text.gsub("\u0000", "").gsub(/[[:cntrl:]&&[^[:space:]]]/, "")
  end

  # Use Gemini's multimodal capabilities to extract text from image-based pages
  def extract_with_vision(file_path, page_number)
    # For now, log a warning — full vision implementation requires
    # rendering PDF pages to images which needs additional dependencies.
    # The text extraction from pdf-reader handles most cases well.
    Rails.logger.info("📷 Page #{page_number}: Image-based — text extraction limited. " \
                      "Consider converting this page to an image for Gemini vision processing.")
    nil
  end

  # Split pages into overlapping chunks of ~CHUNK_SIZE tokens
  def chunk_pages(pages)
    chunks = []
    current_chunk = ""
    current_page = nil

    pages.each do |page|
      sentences = page[:text].split(/(?<=[.!?])\s+/)

      sentences.each do |sentence|
        candidate = current_chunk.empty? ? sentence : "#{current_chunk} #{sentence}"

        if estimate_tokens(candidate) > CHUNK_SIZE && current_chunk.present?
          # Save current chunk
          chunks << { content: current_chunk.strip, page_number: current_page }

          # Start new chunk with overlap from the end of the previous one
          overlap_text = extract_overlap(current_chunk)
          current_chunk = "#{overlap_text} #{sentence}".strip
          current_page = page[:page_number]
        else
          current_chunk = candidate
          current_page ||= page[:page_number]
        end
      end
    end

    # Don't forget the last chunk
    chunks << { content: current_chunk.strip, page_number: current_page } if current_chunk.present?

    chunks
  end

  def estimate_tokens(text)
    text.length / CHARS_PER_TOKEN
  end

  # Extract the last CHUNK_OVERLAP tokens worth of text for overlap
  def extract_overlap(text)
    target_chars = CHUNK_OVERLAP * CHARS_PER_TOKEN
    text.length > target_chars ? text[-target_chars..] : text
  end
end
