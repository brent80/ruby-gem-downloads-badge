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
    status_param.size + format_number_of_downloads.size
  end

  def measure_text
    body = %{
        <html>
          <head>
            <meta name="pdfkit-page_size" content="Legal"/>
            <meta name="pdfkit-orientation" content="Landscape"/>
          </head>
        </html>
      }
    pdfkit = PDFKit.new(body, page_size: 'A4', :toc_l1_font_size => 12)
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
