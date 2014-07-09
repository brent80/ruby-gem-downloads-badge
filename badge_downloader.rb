
class BadgeDownloader
  
  INVALID_COUNT = "invalid"
  
  @attrs = [:color, :style, :shield_conn, :output_buffer, :rubygems_api]
      
  attr_reader *@attrs
  attr_accessor *@attrs

  def initialize( params, output_buffer)
    @color = params[:color].nil? ? "blue" : params[:color] ;
    @style =  params[:style].nil?  || params[:style] != 'flat' ? '': "?style=#{params[:style]}"; 
    @output_buffer = output_buffer
    @shield_conn =  get_faraday_shields_connection
    @rubygems_api = RubygemsApi.new(params) 
  end
  
  def fetch_image_badge_svg
    if show_invalid?
      fetch_image_shield
    else
      fetch_gem_shield
    end
  end
  
  private 
  
  def show_invalid?
    @rubygems_api.has_errors? ||  @rubygems_api.gem_name.nil?
  end
  
  def fetch_gem_shield
    @rubygems_api.fetch_gem_downloads do
      fetch_image_shield
    end
  end
  
 

  
  def fetch_image_shield
    if show_invalid? && !@rubygems_api.gem_name.nil?
      @color = "lightgrey"
      @rubygems_api.downloads_count = BadgeDownloader::INVALID_COUNT
    end
    @rubygems_api.downloads_count = 0 if @rubygems_api.downloads_count.nil?
    if @rubygems_api.downloads_count != BadgeDownloader::INVALID_COUNT
      @rubygems_api.downloads_count = number_with_delimiter(@rubygems_api.downloads_count) 
    end
    resp =   @shield_conn.get do |req|
      req.url "/badge/downloads-#{@rubygems_api.downloads_count }-#{@color}.svg#{@style}"
      req.headers['Content-Type'] = "image/svg+xml; Content-Encoding: gzip; charset=utf-8;"
      req.headers["Cache-Control"] =  "no-cache, no-store, max-age=0, must-revalidate"
      req.headers["Pragma"] = "no-cache"
      req.options.timeout = 10         # open/read timeout in seconds
      req.options.open_timeout = 5
    end
    resp.on_complete {
      @output_buffer << resp.body
      @output_buffer.close
    }
  end
  
  def number_with_delimiter(number, delimiter=",", separator=".")
    begin
      parts = number.to_s.split('.')
      parts[0].gsub!(/(\d)(?=(\d\d\d)+(?!\d))/, "\\1#{delimiter}")
      parts.join separator
    rescue
      number
    end
  end

 
  def get_faraday_shields_connection
    Faraday.new "http://img.shields.io" do |con|
      con.request :url_encoded
      con.request :retry
      con.response :logger
      con.use FaradayNoCacheMiddleware
      con.adapter :em_http
      #   con.use Faraday::HttpCache, store: RedisStore
    end
  end
    
end