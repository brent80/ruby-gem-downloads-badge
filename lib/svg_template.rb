require_relative './helper'
class SvgTemplate
  include Helper
  include Magick

  attr_reader :badge

  delegate :status_param,
            :format_number_of_downloads,
  to: :badge

  def initialize(badge)
    @badge = badge
  end

  def image_width
    measure_text(status_param) + measure_text(format_number_of_downloads)
  end

  def measure_text(string)
    string = string.is_a?(String) ? string : string.to_s
    pdf = PDF::Writer.new(:paper => "A4", :orientation => :landscape)
    pdf.select_font("Verdana")
    pdf.text_width(string, :font_size => 12)
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
