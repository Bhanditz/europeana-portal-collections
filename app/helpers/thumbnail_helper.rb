# frozen_string_literal: true

module ThumbnailHelper
  include ApiHelper

  def thumbnail_url_for_edm_preview(edm_preview, **options)
    api_thumbnail_url_for_edm_preview(edm_preview, options)
  end

  def api_thumbnail_url_for_edm_preview(edm_preview, **options)
    query = if edm_preview.blank?
              { uri: '' }
            else
              edm_preview_uri = URI.parse(edm_preview)
              Rack::Utils.parse_query(edm_preview_uri.query).symbolize_keys
            end

    api_thumbnail_url(query.reverse_merge(options))
  end

  def api_thumbnail_url(**options)
    options = thumbnail_url_options_with_size(options)

    uri = URI.parse(api_url)
    uri.path = uri.path + '/v2/thumbnail-by-url.json'

    query = options.dup.except(:size)
    query[:size] = "w#{options[:size]}"

    uri.query = query.to_query
    uri.to_s
  end

  def thumbnail_url_options_with_size(options)
    options.reverse_merge!(size: 400)
    if options[:size] == 'LARGE'
      options[:size] = 400
    elsif options[:size] == 'MEDIUM'
      options[:size] = 200
    end
    options
  end
end
