class Image < ApplicationRecord
  include Constrainable
  include Pageable

  MAX_CAPTION = 250
  MAX_FILE_SIZE = 50.megabytes
  MAX_PROCESSED_SIZE = 3.megabytes
  MAX_DIMENSION = 1000
  FALLBACK_DIMENSION = 500
  FALLBACK_QUALITY = 70

  belongs_to :user, inverse_of: :images
  has_one_attached :file

  before_validation :normalize_attributes
  after_create_commit :process_image

  validates :caption, presence: true, length: { maximum: MAX_CAPTION }
  validates :file, presence: true, on: :create
  validate :file_size_within_limit, if: -> { file.attached? }, on: :create
  validate :file_type_allowed, if: -> { file.attached? }, on: :create

  default_scope { order(created_at: :desc) }

  def self.search(matches, params, path, opt={})
    matches = matches.includes(:user, file_attachment: :blob)

    if sql = cross_constraint(params[:query], %w{caption})
      matches = matches.where(sql)
    end

    if sql = cross_constraint(params[:user], %w{users.name users.email}, table: :users)
      matches = matches.joins(:user).where(sql)
    end

    if sql = numerical_constraint(params[:width], "active_storage_blobs.metadata->>'width'")
      matches = matches.joins(file_attachment: :blob).where(sql)
    end

    if sql = numerical_constraint(params[:height], "active_storage_blobs.metadata->>'height'")
      matches = matches.joins(file_attachment: :blob).where(sql)
    end

    if sql = numerical_constraint(params[:size], "(active_storage_blobs.byte_size / 1048576.0)", digits: 2)
      matches = matches.joins(file_attachment: :blob).where(sql)
    end

    paginate(matches, params, path, opt)
  end

  def width
    file.attached? && file.blob.metadata[:width] ? file.blob.metadata[:width].to_i : nil
  end

  def height
    file.attached? && file.blob.metadata[:height] ? file.blob.metadata[:height].to_i : nil
  end

  def byte_size
    file.attached? ? file.blob.byte_size : nil
  end

  def size_mb
    byte_size ? (byte_size / 1.megabyte.to_f).round(2) : nil
  end

  def content_type
    file.attached? ? file.blob.content_type : nil
  end

  def thumbnail
    return nil unless file.attached?
    file.variant(resize_to_limit: [nil, 100])
  end

  private

  def normalize_attributes
    caption&.squish!
  end

  def file_size_within_limit
    if file.blob.byte_size > MAX_FILE_SIZE
      errors.add(:file, "is too large (maximum is #{MAX_FILE_SIZE / 1.megabyte}MB)")
    end
  end

  def file_type_allowed
    allowed_types = %w[image/jpeg image/jpg image/png image/heic image/heif image/webp]

    unless allowed_types.include?(file.content_type)
      if file.content_type == "image/gif"
        errors.add(:file, "GIF files are not supported")
      else
        errors.add(:file, "must be a JPEG, PNG, HEIC, or WebP image")
      end
    end
  end

  def process_image
    return unless file.attached?

    # Check if image has already been processed by us
    return if file.blob.metadata[:processed] == true

    # Download file to a temporary location
    tempfile = Tempfile.new(["original", File.extname(file.filename.to_s)])
    tempfile.binmode
    tempfile.write(file.download)
    tempfile.rewind
    tempfile.close

    begin
      # Extract EXIF data before processing
      extract_exif_data(tempfile.path)

      # Load image with Vips - try with fail_on option to ignore metadata errors
      begin
        image = Vips::Image.new_from_file(tempfile.path, access: :sequential, fail_on: :none)
      rescue Vips::Error => e
        Rails.logger.warn("Failed to load image with sequential access: #{e.message}, retrying without it")
        image = Vips::Image.new_from_file(tempfile.path, fail_on: :none)
      end
      original_format = detect_format(file.content_type)

      # Determine if we need to convert format
      should_convert = should_convert_format?(original_format)

      # Process: resize if needed
      processed_image = resize_if_needed(image, MAX_DIMENSION)

      # Prepare output settings
      if should_convert
        output_ext = "jpg"
        new_content_type = "image/jpeg"
        new_filename = file.filename.to_s.gsub(/\.[^.]+$/, ".jpg")
      else
        output_ext = file_extension(file.content_type)
        new_content_type = file.content_type
        new_filename = file.filename.to_s
      end

      # Save processed image to temporary file
      output_path = Rails.root.join("tmp", "processed_#{SecureRandom.hex}.#{output_ext}")
      save_image(processed_image, output_path.to_s, should_convert ? 85 : nil)

      # Check file size
      output_size = File.size(output_path)

      if output_size > MAX_PROCESSED_SIZE
        # Try more aggressive compression
        File.delete(output_path)
        processed_image = resize_if_needed(image, FALLBACK_DIMENSION)

        output_ext = "jpg"
        new_content_type = "image/jpeg"
        new_filename = file.filename.to_s.gsub(/\.[^.]+$/, ".jpg")

        save_image(processed_image, output_path.to_s, FALLBACK_QUALITY)
        output_size = File.size(output_path)

        if output_size > MAX_PROCESSED_SIZE
          File.delete(output_path)
          raise "Image is too large after processing (#{(output_size / 1.megabyte.to_f).round(2)}MB > #{MAX_PROCESSED_SIZE / 1.megabyte}MB)"
        end
      end

      # Get final dimensions
      final_image = Vips::Image.new_from_file(output_path.to_s, fail_on: :none)
      final_width = final_image.width
      final_height = final_image.height

      # Create a new blob with the processed image
      old_blob = file.blob

      # Upload the processed file
      processed_blob = File.open(output_path, "rb") do |f|
        ActiveStorage::Blob.create_and_upload!(
          io: f,
          filename: new_filename,
          content_type: new_content_type,
          metadata: {
            width: final_width,
            height: final_height,
            processed: true,
            identified: true,
            analyzed: true
          }
        )
      end

      # Update the attachment directly without triggering callbacks
      file.attachment.update!(blob: processed_blob)

      # Purge the old blob
      old_blob.purge if old_blob

      # Clean up after successful attach
      File.delete(output_path) if File.exist?(output_path)

      # Save EXIF data changes
      update_columns(
        latitude: latitude,
        longitude: longitude,
        date_taken: date_taken
      ) if latitude_changed? || longitude_changed? || date_taken_changed?

    rescue => e
      Rails.logger.error("Image processing error for #{self.class.name} ID #{id}: #{e.message}")
      Rails.logger.error("Error class: #{e.class}")
      Rails.logger.error(e.backtrace.first(10).join("\n"))
      # Re-raise the error so we can see it in development
      raise e if Rails.env.development?
    ensure
      # Always clean up the original tempfile
      tempfile.unlink if tempfile && File.exist?(tempfile.path)
    end
  end

  def extract_exif_data(file_path)
    image = Vips::Image.new_from_file(file_path, fail_on: :none)

    # Extract GPS data - check both ifd0 and ifd3 (HEIC files use ifd3)
    begin
      %w[exif-ifd0 exif-ifd3].each do |ifd|
        lat_field = "#{ifd}-GPSLatitude"
        lon_field = "#{ifd}-GPSLongitude"

        if image.get_typeof(lat_field) != 0 && image.get_typeof(lon_field) != 0
          # Get ref values and extract just the first character (N/S/E/W)
          lat_ref = (image.get("#{ifd}-GPSLatitudeRef") rescue "N").to_s[0]
          lon_ref = (image.get("#{ifd}-GPSLongitudeRef") rescue "E").to_s[0]
          lat = parse_gps_coordinate(image.get(lat_field), lat_ref)
          lon = parse_gps_coordinate(image.get(lon_field), lon_ref)
          self.latitude = lat if lat
          self.longitude = lon if lon
          break if latitude && longitude
        end
      end
    rescue => e
      Rails.logger.debug("Could not extract GPS data: #{e.message}")
    end

    # Extract date taken - check ifd0 and ifd2
    begin
      %w[exif-ifd0-DateTime exif-ifd2-DateTimeOriginal].each do |field|
        if image.get_typeof(field) != 0
          datetime_str = image.get(field)
          self.date_taken = parse_exif_datetime(datetime_str)
          break if date_taken
        end
      end
    rescue => e
      Rails.logger.debug("Could not extract date taken: #{e.message}")
    end
  rescue => e
    Rails.logger.info("Could not extract EXIF data: #{e.message}")
  end

  def parse_gps_coordinate(coord_string, ref)
    # EXIF GPS coordinates are in format "degrees/1 minutes/1 seconds/100"
    # Example: "57/1 13/1 3998/100" means 57°13'39.98"

    # Extract numbers from rational format
    parts = coord_string.to_s.scan(/(\d+)\/(\d+)/).map do |numerator, denominator|
      numerator.to_f / denominator.to_f
    end

    return nil if parts.empty?

    degrees = parts[0] || 0
    minutes = parts[1] || 0
    seconds = parts[2] || 0

    # Convert to decimal degrees
    decimal = degrees + (minutes / 60.0) + (seconds / 3600.0)

    # Apply direction (South and West are negative)
    decimal *= -1 if ref.to_s =~ /[SW]/i

    decimal.round(6)
  rescue => e
    Rails.logger.debug("GPS coordinate parsing error: #{e.message}")
    nil
  end

  def parse_exif_datetime(datetime_str)
    # EXIF datetime format: "YYYY:MM:DD HH:MM:SS"
    DateTime.strptime(datetime_str.to_s, "%Y:%m:%d %H:%M:%S")
  rescue
    nil
  end

  def detect_format(content_type)
    case content_type
    when "image/jpeg", "image/jpg" then "jpeg"
    when "image/png" then "png"
    when "image/gif" then "gif"
    when "image/webp" then "webp"
    when "image/heic", "image/heif" then "heic"
    else "other"
    end
  end

  def should_convert_format?(format)
    # Convert HEIC and other non-web formats to JPEG
    # Keep JPG, PNG, GIF, WEBP as-is
    !["jpeg", "png", "gif", "webp"].include?(format)
  end

  def file_extension(content_type)
    case content_type
    when "image/jpeg", "image/jpg" then "jpg"
    when "image/png" then "png"
    when "image/gif" then "gif"
    when "image/webp" then "webp"
    else "jpg"
    end
  end

  def resize_if_needed(image, max_dimension)
    width = image.width
    height = image.height

    if width > max_dimension || height > max_dimension
      scale = max_dimension.to_f / [width, height].max
      image.resize(scale)
    else
      image
    end
  end

  def save_image(image, path, quality = nil)
    # Ensure image is in sRGB color space
    image = image.colourspace("srgb") if image.bands >= 3

    ext = File.extname(path).downcase
    case ext
    when ".jpg", ".jpeg"
      quality ||= 85
      image.jpegsave(path, Q: quality, strip: true, optimize_coding: true)
    when ".png"
      image.pngsave(path, compression: 9, strip: true)
    when ".webp"
      image.webpsave(path, Q: quality || 85, strip: true)
    when ".gif"
      image.gifsave(path, strip: true)
    else
      # Default to JPEG
      image.jpegsave(path, Q: quality || 85, strip: true, optimize_coding: true)
    end
  end
end
