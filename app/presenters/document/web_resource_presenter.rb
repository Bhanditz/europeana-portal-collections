module Document
  ##
  # Blacklight document presenter for a Europeana web resource
  class WebResourcePresenter < DocumentPresenter
    include ActionView::Helpers::NumberHelper
    include ApiHelper
    include MediaProxyHelper
    include Metadata::Rights
    include ThumbnailHelper

    delegate :params, to: :controller

    def initialize(document, controller, configuration = controller.blacklight_config, record = nil, record_presenter = nil)
      super(document, controller, configuration)
      @record = record
      @record_presenter = record_presenter || (record.nil? ? nil : RecordPresenter.new(record, controller))
    end

    ##
    # This is the data required by the view template
    def media_item
      {
        media_type: media_type,
        rights: simple_rights_label_data,
        downloadable: downloadable?,
        playable: playable?,
        thumbnail: thumbnail,
        play_url: play_url,
        play_html: play_html,
        technical_metadata: media_metadata,
        download: {
          url: downloadable? ? download_url : false,
          text: t('site.object.actions.download')
        },
        external_media: external_media_url
      }.merge(player_indicator)
    end

    def player_indicator
      if player.nil?
        { is_unknown_type: url }
      else
        { :"is_#{player}" => true }
      end
    end

    def external_media_url
      if download_url == @record_presenter.edm_object
        @record_presenter.is_shown_by_or_at
      else
        download_url
      end
    end

    def play_url
      @play_url ||= begin
        @record_presenter.iiif_manifest || download_url
      end
    end

    def play_html
      @play_html ||= begin
        return nil unless media_type == 'oembed'
        @controller.oembed_html[url][:html]
      end
    end

    def url
      @url ||= begin
        url = field_value('about')
        @controller.url_conversions[url] || url
      end
    end

    def media_rights
      @media_rights ||= begin
        rights = field_value('webResourceEdmRights')
        rights.blank? ? @record_presenter.media_rights : rights
      end
    end

    def mime_type
      @mime_type ||= field_value('ebucoreHasMimeType')
    end

    def record_type
      @record_type ||= @record_presenter.field_value('type')
    end

    # Media type function normalises mime types
    def media_type
      @media_type ||= (media_type_special_case || media_type_from_mime_type || media_type_from_record_type)
    end

    def media_type_special_case
      case
      when @record_presenter.iiif_manifest
        'iiif'
      when @controller.oembed_html.key?(url)
        'oembed'
      end
    end

    def media_type_from_mime_type
      case (mime_type || '').downcase
      when /^audio\//
        'audio'
      when /^image\//
        'image'
      when /^video\//
        'video'
      when /^text\//, /\/pdf$/
        'text'
      end
    end

    def media_type_from_record_type
      case record_type
      when '3D'
        '3D'
      when 'SOUND'
        'audio'
      else
        record_type.downcase
      end
    end

    def edm_media_type
      @edm_media_type ||= begin
        if record_type == '3D' || %w(iiif oembed).include?(media_type)
          record_type
        elsif media_type == 'audio'
          'SOUND'
        else
          media_type.upcase
        end
      end
    end

    def download_url
      @download_url ||= mime_type.present? ? media_proxy_url(@record.fetch('about', '/'), url) : url
    end

    def media_metadata
      width = field_value('ebucoreWidth')
      height = field_value('ebucoreHeight')

      file_size = number_to_human_size(field_value('ebucoreFileByteSize')) || ''
      {
        mime_type: mime_type,
        format: field_value('ebucoreHasMimeType'),
        file_size: file_size.split(' ').first,
        file_unit: file_size.split(' ').last,
        codec: field_value('edmCodecName'),
        width: width,
        height: height,
        width_or_height: !(width.blank? && height.blank?),
        size_unit: 'pixels',
        runtime: field_value('ebucoreDuration'),
        runtime_unit: t('site.object.meta-label.runtime-unit-seconds'),
        attribution_plain: field_value('textAttributionSnippet'),
        attribution_html: field_value('htmlAttributionSnippet'),
        colours: colour_palette_data,

        dc_description: field_value('dcDescription'),
        dc_creator: field_value('dcCreator'),
        dc_source: field_value('dcSource'),
        dc_rights: field_value('webResourceDcRights'),
        edm_rights: {
          model: simple_rights(EDM::Rights.normalise(field_value('webResourceEdmRights')))
        }.as_json.to_s.gsub!('=>', ': ').gsub!('nil', 'false')
      }
    end

    def colour_search_url(colour)
      query_params = { f: { 'COLOURPALETTE' => [colour], 'TYPE' => ['IMAGE'] } }
      search_path(query_params)
    end

    def colour_palette_data
      colours = document.fetch('edmComponentColor', [])
      {
        present: !colours.blank?,
        items: colours.map do |colour|
          {
            hex: colour,
            url: colour_search_url(colour)
          }
        end
      }
    end

    def is_avi?
      %w(video/avi video/msvideo video/x-msvideo image/avi video/xmpg2
         application/x-troff-msvideo audio/aiff audio/avi).include?(mime_type)
    end

    ##
    # Tests for displayability of this web resource
    #
    # Each of these tests should be run *in order* until one returns a non-nil
    # value which may be either true or false, indicating whether or not this
    # web resource is displayable.
    #
    # @return [Array<Proc>] lambdas to test displayability
    def displayable_tests
      [
        # TRUE if for edm:object and no other web resources are displayable
        -> { for_edm_object? && @record_presenter.media_web_resource_presenters.reject { |p| p == self }.none?(&:displayable?) ? true : nil },
        # FALSE if for edm:object but edm:object is just a thumbnail of edm:isShownBy (which will be shown instead)
        -> { for_edm_object? && @record_presenter.edm_object_thumbnails_edm_is_shown_by? ? false : nil },
        # TRUE if for edm:isShownBy
        -> { for_edm_is_shown_by? ? true : nil },
        # TRUE if for a hasView and MIME type is known
        -> { for_has_view? && mime_type.present? ? true : nil },
        # TRUE if for an oEmbed
        -> { media_type == 'oembed' ? true : nil },
        # FALSE otherwise
        -> { false }
      ]
    end

    def displayable?
      return @displayable if defined?(@displayable)

      displayable_tests.each do |test|
        unless defined?(@displayable)
          test_result = test.call
          @displayable = test_result unless test_result.nil?
        end
      end

      @displayable
    end

    def playable?
      if url.blank? ||
          (mime_type.blank? && !playable_without_mime_type?) ||
          (mime_type == 'video/mpeg') ||
          (media_type == 'text' && mime_type == 'text/plain; charset=utf-8') ||
          (media_type == 'video' && mime_type == 'text/plain; charset=utf-8') ||
          is_avi?
        false
      else
        true
      end
    end

    def playable_without_mime_type?
      %w(iiif oembed).include?(media_type)
    end

    def downloadable?
      if url.blank? ||
          download_disabled? ||
          media_type == 'iiif' ||
          media_type == 'oembed' ||
          (media_type == 'text' && mime_type == 'text/plain; charset=utf-8') ||
          (media_type == 'video' && mime_type == 'text/plain; charset=utf-8')
        false
      else
        for_has_view? || for_edm_is_shown_by?
      end
    end

    def for_edm_object?
      url == @record_presenter.edm_object
    end

    def for_edm_is_shown_by?
      url == @record_presenter.edm_is_shown_by
    end

    def for_has_view?
      @record_presenter.has_views.include?(url)
    end

    def download_disabled?
      # blacklisted1 = %w(http://www.europeana.eu/rights/rr-p/ http://www.europeana.eu/rights/rr-r/ http://www.europeana.eu/rights/rr-f/)
      # blacklisted2 = %w(http://www.europeana.eu/rights/test-orphan http://www.europeana.eu/rights/unknown)
      # blacklisted1.include?(media_rights) || blacklisted2.include?(media_rights)
      false
    end

    def thumbnail
      siblings = @record_presenter.displayable_media_web_resource_presenters
      use_small = (siblings.size > 1) && (siblings.first != self)
      if edm_object_thumbnail?
        @record_presenter.media_web_resource_presenters.detect { |p| p.url == @record_presenter.edm_object }.api_thumbnail(use_small)
      else
        api_thumbnail(use_small)
      end
    end

    def edm_object_thumbnail?
      for_edm_is_shown_by? &&
        @record_presenter.edm_object_thumbnails_edm_is_shown_by?
    end

    def api_thumbnail(use_small)
      width = use_small ? '200' : '400'
      api_thumbnail_url(uri: url, size: width, type: edm_media_type)
    end

    def player
      @player ||= begin
        case media_type
        when 'text'
          (mime_type =~ /\/pdf$/) ? :pdf : :text
        else
          media_type.to_sym
        end
      end
    end
  end
end
