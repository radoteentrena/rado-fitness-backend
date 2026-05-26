module Admin
  class BooksController < Admin::ApplicationController
    before_action :require_super_admin

    def index
      @books = Book.order(created_at: :desc)
    end

    def show
      @book = Book.find(params[:id])
    end

    def new
      @book = Book.new
    end

    def create
      @book = Book.new(book_params)

      if @book.save
        BookIngestionJob.perform_later(@book.id)
        redirect_to admin_book_path(@book), notice: "Book uploaded. Ingestion running in background."
      else
        render :new, status: :unprocessable_entity
      end
    end

    private

    def book_params
      params.require(:book).permit(:title, :author, :pdf)
    end
  end
end
