module Remarkable
  class CustomRenderer < Redcarpet::Render::HTML
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
      link = "/#{link}" unless link.match?(/\//)
      width = get_width(title)
      klass = get_klass(title)
      %Q(<img src="#{link}" alt="#{alt}" class="styled #{klass}" width="#{width}">)
    end

    private

    def link_with_target(link, text=nil)
      return unless link =~ /\A(.+)\|(\w*)\z/
      link = $1
      trgt = $2.blank?? "external" : $2
      text = link if text.blank?
      [link, trgt, text]
    end

    def get_width(inst)
      if inst&.match(/([1-9]\d*)%/) && $1.to_i <= 100 && $1.to_i >= 10
        "#{$1}%"
      elsif inst&.match(/([1-9]\d*)/) && $1.to_i <= 300 && $1.to_i >= 100
        "#{$1}px"
      else
        "300px"
      end
    end

    def get_klass(inst)
      if inst&.match?(/R/i)
        "float-right ml-3 mt-1 mb-1"
      elsif inst&.match?(/L/i)
        "float-left mr-3 mt-1 mb-1"
      else
        "mx-auto d-block mt-3 mb-3"
      end
    end
  end

  def to_html(text, filter_html: false, images: false)
    return "" unless text.present?
    preprocess_images(text) if images
    renderer = CustomRenderer.new(filter_html: filter_html)
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

  def preprocess_images(text)
    text.gsub!(/IMG\[([1-9]\d*)(?:\|([^\]]*))?\]/) do |m|
      id = $1.to_i
      op = $2
      if p = Picture.find_by(id: $1.to_i)
        url = Rails.application.routes.url_helpers.rails_blob_path(p.image, only_path: true)
        options = {
          title: p.title,
          alt: p.title,
        }
        options[:width] = $1 if op =~ /w(?:idth)?[=:]([1-9]\d*)/
        options[:height] = $1 if op =~ /(?<!t)h(?:eight)?[=:]([1-9]\d*)/
        '<img src="%s" %s>' % [url, options.map{|k,v| '%s="%s"' % [k, v]}.join(" ")]
      else
        "IMG[%d?]" % id
      end
    end
  end
end
