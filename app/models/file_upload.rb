class FileUpload < ApplicationRecord
  belongs_to :admin
  has_one_attached :file
end
