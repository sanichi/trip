module ImageHelper
  def image_coordinates(latitude, longitude, decimals = 4)
    # Return nil if both are missing
    return nil if latitude.nil? && longitude.nil?

    parts = []

    # Format latitude if present
    if latitude
      lat_abs = latitude.abs
      lat_dir = latitude >= 0 ? "N" : "S"
      lat_value = decimals > 0 ? lat_abs.round(decimals) : lat_abs.round.to_i
      parts << "#{lat_dir} #{lat_value}"
    end

    # Format longitude if present
    if longitude
      lon_abs = longitude.abs
      lon_dir = longitude >= 0 ? "E" : "W"
      lon_value = decimals > 0 ? lon_abs.round(decimals) : lon_abs.round.to_i
      parts << "#{lon_dir} #{lon_value}"
    end

    parts.join(" ")
  end

  def image_taken(taken, include_time = true)
    return nil if taken.nil?

    if include_time
      taken.strftime("%H:%M %b %-d, %Y")
    else
      taken.strftime("%b %-d, %Y")
    end
  end

  def image_size(byte_size)
    return nil if byte_size.nil?

    kb = 1024.0
    mb = kb * 1024

    if byte_size < kb
      # Less than 1 KB: show bytes
      "#{byte_size.round} B"
    elsif byte_size < mb
      # Less than 1 MB: show KB rounded
      "#{(byte_size / kb).round} KB"
    elsif byte_size < 100 * mb
      # 1 MB to 100 MB: show 3 significant figures
      size_mb = byte_size / mb
      if size_mb < 10
        # 1.00 - 9.99 MB: 2 decimal places (e.g., "1.23 MB")
        "#{size_mb.round(2)} MB"
      else
        # 10.0 - 99.9 MB: 1 decimal place (e.g., "12.3 MB")
        "#{size_mb.round(1)} MB"
      end
    else
      # 100 MB and above: round to integer
      "#{(byte_size / mb).round} MB"
    end
  end

  def image_type(content_type)
    return nil if content_type.nil?

    # Extract the subtype after "image/"
    type = content_type.sub("image/", "")

    # Special case for jpeg - display as JPG
    type == "jpeg" ? "JPG" : type.upcase
  end
end
