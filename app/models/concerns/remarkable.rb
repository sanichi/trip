module Remarkable
  class CustomRenderer < Redcarpet::Render::HTML
    def initialize(options = {})
      @guest = options.delete(:guest) { true }
      super(options)
    end

    def link(link, title, alt_text)
      if lnk_trg_txt = link_with_target(link, alt_text)
        '<a href="%s" target="%s">%s</a>' % lnk_trg_txt
      else
        '<a href="%s">%s</a>' % [link, alt_text]
      end
    end

    def autolink(link, link_type)
      if lnk_trg_txt = link_with_target(link)
        '<a href="%s" target="%s">%s</a>' % lnk_trg_txt
      else
        '<a href="%s">%s</a>' % [link, link]
      end
    end

    def image(link, title, alt)
      # Detect media type based on link format
      if link.match?(/\A\d+\z/)
        # Numeric ID → Active Storage image
        render_active_storage_image(link.to_i, title, alt)
      elsif link.match?(/\A[a-zA-Z0-9_-]{11}\z/)
        # 11-char alphanumeric → YouTube video
        render_youtube_video(link, title, alt)
      else
        error_or_nothing("Invalid media ID: \"#{link}\" (use numeric ID for images or 11-character YouTube video ID)")
      end
    end

    private

    def render_active_storage_image(image_id, title, alt)
      # Look up image
      image = Image.find_by(id: image_id)
      unless image
        return error_or_nothing("Image not found: ID #{image_id}")
      end

      # Parse breakpoints and caption flag from title
      result = parse_breakpoints(title)
      unless result
        return error_or_nothing("Invalid breakpoint syntax: \"#{title}\" (use 1-6 integers between 1-12, optionally append 'c' for centered caption or 'C' for left-aligned caption)")
      end

      # Use image caption as alt text if none provided
      alt_text = alt.present? ? alt : image.caption
      image_url = Rails.application.routes.url_helpers.rails_blob_path(image.file, only_path: true)

      # Generate responsive image HTML
      if result[:show_caption]
        caption_class = result[:center_caption] ? "figure-caption text-center px-2 pb-2" : "figure-caption px-2 pb-2"
        content = %Q(<figure class="figure w-100 border rounded"><img src="#{image_url}" alt="#{alt_text}" class="img-fluid figure-img" width="#{image.width}" height="#{image.height}"><figcaption class="#{caption_class}">#{image.caption}</figcaption></figure>)
      else
        content = %Q(<img src="#{image_url}" alt="#{alt_text}" class="img-fluid border rounded" width="#{image.width}" height="#{image.height}">)
      end

      wrap_in_centered_div(content, result[:breakpoints])
    end

    def render_youtube_video(video_id, title, alt)
      # Parse breakpoints and caption flag from title
      result = parse_breakpoints(title)
      unless result
        return error_or_nothing("Invalid breakpoint syntax: \"#{title}\" (use 1-6 integers between 1-12, optionally append 'c' for centered caption or 'C' for left-aligned caption)")
      end

      # Build YouTube embed iframe
      embed_url = "https://www.youtube.com/embed/#{video_id}"
      iframe = %Q(<div class="ratio ratio-16x9 border rounded"><iframe src="#{embed_url}" title="YouTube video player" allow="clipboard-write; picture-in-picture; web-share" allowfullscreen></iframe></div>)
      caption_class = result[:center_caption] ? "figure-caption text-center px-2 pb-2" : "figure-caption px-2 pb-2"

      # Check if full width (xs: 12 only, which Bootstrap cascades upward)
      if result[:breakpoints] == { xs: 12 }
        # Full width - simple structure
        if alt.present? && result[:show_caption]
          # Wrap with caption if available and requested
          %Q(<figure class="figure w-100">#{iframe}<figcaption class="#{caption_class}">#{alt}</figcaption></figure>)
        else
          iframe
        end
      else
        # Partial width - caption must be inside column wrapper
        center_class = Sni::Center.call(**result[:breakpoints])

        if result[:show_caption] && alt.present?
          # Put both video and caption inside the column wrapper
          %Q(<div class="row"><div class="#{center_class}"><figure class="figure w-100">#{iframe}<figcaption class="#{caption_class}">#{alt}</figcaption></figure></div></div>)
        else
          # Just video in column wrapper
          %Q(<div class="row"><div class="#{center_class}">#{iframe}</div></div>)
        end
      end
    end

    def wrap_in_centered_div(content, breakpoints)
      center_class = Sni::Center.call(**breakpoints)
      %Q(<div class="#{center_class}">#{content}</div>)
    end

    def link_with_target(link, text=nil)
      return unless link =~ /\A(.+)\|(\w*)\z/
      link = $1
      trgt = $2.blank?? "external" : $2
      text = link if text.blank?
      [link, trgt, text]
    end

    def error_or_nothing(message)
      @guest ? "" : %Q(<div class="alert alert-danger">#{message}</div>)
    end

    def parse_breakpoints(title)
      if title.blank?
        return { breakpoints: { xs: 12 }, show_caption: false, center_caption: false }
      end

      # Split by comma and strip whitespace
      values = title.split(',').map(&:strip)

      # Check if last value is 'c' or 'C' (caption flag)
      show_caption = false
      center_caption = false
      if values.last == 'c'
        show_caption = true
        center_caption = true
        values.pop  # Remove the 'c' from values
      elsif values.last == 'C'
        show_caption = true
        center_caption = false
        values.pop  # Remove the 'C' from values
      end

      # If only 'c' or 'C' was provided, use default breakpoints
      if values.empty?
        return { breakpoints: { xs: 12 }, show_caption: show_caption, center_caption: center_caption }
      end

      # Check if all remaining values are valid integers
      int_values = values.map do |v|
        return nil unless v.match?(/\A\d+\z/)
        v.to_i
      end

      # Validate: 1-6 values, all between 1-12
      return nil if int_values.empty? || int_values.size > 6
      return nil if int_values.any? { |v| v < 1 || v > 12 }

      # Map to breakpoints (xs, sm, md, lg, xl, xx)
      breakpoint_names = [:xs, :sm, :md, :lg, :xl, :xx]
      breakpoints = {}
      int_values.each_with_index do |value, index|
        breakpoints[breakpoint_names[index]] = value
      end

      { breakpoints: breakpoints, show_caption: show_caption, center_caption: center_caption }
    end
  end

  def to_html(text, filter_html: false, guest: true)
    return "" unless text.present?
    renderer = CustomRenderer.new(filter_html: filter_html, guest: guest)
    options =
    {
      autolink: true,
      fenced_code_blocks: true,
      no_intra_emphasis: true,
      strikethrough: true,
      superscript: true,
      tables: true,
      underline: true,
    }
    markdown = Redcarpet::Markdown.new(renderer, options)
    markdown.render(text).html_safe
  end
end
