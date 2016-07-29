require_relative './helper'
class SvgTemplate
  include Helper

  attr_reader :badge

  delegate :status_param,
  :format_number_of_downloads,
  :logo_width,
  :logo_padding,
  :logo_param,
  :image_colour,
  :style_param,
  to: :badge

  def initialize(badge)
    @badge = badge
    @svg_logo_width = logo_width.present? ? logo_width : (logo_param.present? ? 14 : 0)
    @svg_logo_padding = logo_param.present? ? 3: 0
    @svg_social_links = style_param != 'social' || link_param.blank? ? [] : link_param
  end

  def svg_color_number
    @svg_color ||= fetch_color_hex(image_colour)
    @svg_color
  end

  def image_width
    status_param_width + formatted_downloads_width
  end

  def status_param_width
    @status_param_width ||= measure_text(status_param) + 10 + @svg_logo_width + @svg_logo_padding
    @status_param_width
  end

  def formatted_downloads_width
    @formatted_downloads_width ||= measure_text(format_number_of_downloads) + 10
    @formatted_downloads_width
  end

  def status_param_and_logo_width_text
    (status_param_width + @svg_logo_width+ @svg_logo_padding)/2
  end

  def formatted_download_text_width
    (status_param_width + formatted_downloads_width/2 -1)
  end

  def measure_text(string)
    string = string.is_a?(String) ? string : string.to_s
    document = Prawn::Document.new(:page_size => "A4", :page_layout => :landscape)
    document.font_families["Verdana"] = {
      :normal => { :file => File.join(root, "fonts", "Verdana.ttf"), :font => "Verdana" }
    }
    document.font('Verdana')
    #document_font_metrics = Prawn::FontMetricCache.new(document)
    width = document.width_of(string, :size => 11)
    width = width.blank? ? 0 : width.to_i
    # Increase chances of pixel grid alignment.
    width=width+1 if (width % 2 === 0)
    width
  end

  def fetch_badge_image
    case image_extension
    when 'png'
      create_png
    else
      create_svg
    end
  end

  def default_template
    badge_style = style_param.present? ? style_param : 'flat'
    @default_template ||= File.expand_path(File.join(root, 'templates', "svg_#{badge_style}.erb"))
  end

  def create_svg
    Tilt.new(default_template).render(self)
  end

  def create_png
    ImageConvert.svg_to_png(create_svg)
  end

  def method_missing(sym, *args, &block)
    @badge.public_send(sym, *args, &block)
  end

  def respond_to_missing?(method_name, include_private = false)
    @badge.public_methods.include?(method_name) || super
  end
end
