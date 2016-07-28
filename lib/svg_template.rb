require_relative './helper'
class SvgTemplate
  include Helper

  attr_reader :badge

  delegate :status_param,
            :format_number_of_downloads,
  to: :badge

  def initialize(badge)
    @badge = badge
  end

  def image_width
    status_param_width + formatted_downloads_width
  end

  def status_param_width
    measure_text(status_param) + 10 + logo_width + logo_padding
  end

  def formatted_downloads_width
    measure_text(format_number_of_downloads) + 10
  end

  def measure_text(string)
    string = string.is_a?(String) ? string : string.to_s
    document = Prawn::Document.new(:page_size => "A4", :page_layout => :landscape)
    document.font_families["Verdana"] = {
      :normal => { :file => File.join(root, "fonts", "Verdana.ttf"), :font => "Verdana" }
    }
    document.font('Verdana')
    document_font_metrics = Prawn::FontMetricCache.new(document)
    width = document_font_metrics.width_of(string, :size => 11)
    width = width.blank? ? 0 : width.to_i
    # Increase chances of pixel grid alignment.
    width=width+1 if (width % 2 === 0)
    width
  end

  def default_template
    @default_template ||= File.expand_path(File.join(root, 'templates', "svg_default.erb"))
  end

  def template_data
    Tilt.new(default_template).render(self)
  end

  def create_png
    ImageConvert.svg_to_png(template_data)
  end

  def method_missing(sym, *args, &block)
    @badge.public_send(sym, *args, &block)
  end

  def respond_to_missing?(method_name, include_private = false)
    @badge.public_methods.include?(method_name) || super
  end
end
