class BookIngestionJob < ApplicationJob
  queue_as :default

  discard_on ActiveRecord::RecordNotFound
  retry_on StandardError, attempts: 2, wait: :polynomially_longer

  def perform(book_id)
    book = Book.find(book_id)
    return unless book.pdf.attached?

    book.update!(ingestion_status: :processing)

    book.pdf.blob.open do |tempfile|
      BookIngestionService.new.ingest(tempfile.path, title: book.title, author: book.author)
    end

    book.update!(ingestion_status: :completed)
  rescue StandardError => e
    book&.update!(ingestion_status: :failed)
    Rails.logger.error("[BookIngestionJob] Failed for book #{book_id}: #{e.message}")
    raise
  end
end
