module Admin
  module BooksHelper
    STATUS_CLASSES = {
      "pending"    => "bg-gray-100 text-gray-700 dark:bg-gray-800 dark:text-gray-300",
      "processing" => "bg-yellow-100 text-yellow-800 dark:bg-yellow-900/30 dark:text-yellow-400",
      "completed"  => "bg-green-100 text-green-800 dark:bg-green-900/30 dark:text-green-400",
      "failed"     => "bg-red-100 text-red-800 dark:bg-red-900/30 dark:text-red-400"
    }.freeze

    def ingestion_status_class(status)
      STATUS_CLASSES[status.to_s] || STATUS_CLASSES["pending"]
    end
  end
end
