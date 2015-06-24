module Europeana
  ##
  # Configures Blacklight for Europeana Portal & Channels
  module BlacklightConfig
    extend ActiveSupport::Concern
    include ::Blacklight::Base

    included do
      def self.channels_query_facet
        channels = Europeana::Portal::Application.config.channels.dup
        channels.each_with_object({}) do |(k, v), hash|
          hash[k] = { label: k, fq: v[:query] }
        end
      end

      configure_blacklight do |config|
        # Default parameters to send to Europeana for all search-like requests.
        # @see SolrHelper#solr_search_params
        config.default_solr_params = {
          rows: 12
        }

        # Response models
        config.repository_class = Europeana::Blacklight::ApiRepository
        config.search_builder_class = SearchBuilder
        config.response_model = Europeana::Blacklight::Response
        config.document_model = Europeana::Blacklight::Document
        config.document_presenter_class = MustacheDocumentPresenter

        # items to show per page, each number in the array represents another
        # option to choose from.
        config.per_page = [12, 24, 48, 96]

        # Field configuration for search results/index views
        config.index.title_field = 'title'
        config.index.display_type_field = 'type'
        config.index.timestamp_field = nil # Europeana's is in microseconds

        # Fields to be displayed in the index (search results) view
        #   The ordering of the field names is the order of the display 
        config.add_index_field 'title'
        config.add_index_field 'edmPreview'
        config.add_index_field 'edmAgentLabelLangAware'
        config.add_index_field 'dcDescription'
        config.add_index_field 'edmConceptPrefLabelLangAware',
          separator: '; ', limit: 4
        config.add_index_field 'year'
        config.add_index_field 'dataProvider'
        config.add_index_field 'edmIsShownAt'

        # Max number of rows to retrieve for each facet
        config.default_facet_limit = 7

        # Facet fields in the order they should be displayed.
        config.add_facet_field 'CHANNEL', query: channels_query_facet
        config.add_facet_field 'TYPE', limit: true
        config.add_facet_field 'YEAR', limit: 30, range: true
        config.add_facet_field 'REUSABILITY', limit: true
        config.add_facet_field 'COUNTRY', limit: true
        config.add_facet_field 'LANGUAGE', limit: true
        config.add_facet_field 'PROVIDER', limit: true
        config.add_facet_field 'DATA_PROVIDER', limit: true

        # Send all facet field names to Solr.
        config.add_facet_fields_to_solr_request!

        # Fields to be displayed in the object view, in the order of display.
        config.add_show_field 'agents.prefLabel'
        config.add_show_field 'agents.begin'
        config.add_show_field 'agents.end'
        config.add_show_field 'proxies.dcType'
        config.add_show_field 'proxies.dcCreator'
        config.add_show_field 'proxies.dcFormat'
        config.add_show_field 'proxies.dcIdentifier'
        config.add_show_field 'proxies.dctermsCreated'
        config.add_show_field 'aggregations.webResources.dctermsCreated'
        config.add_show_field 'proxies.dctermsExtent'
        config.add_show_field 'proxies.dcTitle'
        config.add_show_field 'europeanaAggregation.edmCountry'
        config.add_show_field 'edmDatasetName'
        config.add_show_field 'aggregations.edmIsShownAt'
        config.add_show_field 'aggregations.edmIsShownBy'
        config.add_show_field 'europeanaAggregation.edmLanguage'
        config.add_show_field 'europeanaAggregation.edmPreview'
        config.add_show_field 'aggregations.edmProvider'
        config.add_show_field 'aggregations.edmDataProvider'
        config.add_show_field 'aggregations.edmRights'
        config.add_show_field 'places.latitude'
        config.add_show_field 'places.longitude'
        config.add_show_field 'type'
        config.add_show_field 'year'

        # "fielded" search configuration.
        config.add_search_field('', label: 'All Fields')
        %w(title who what when where subject).each do |field_name|
          config.add_search_field(field_name)
        end

        # Prevent BL's "did you mean" spellcheck feature kicking in
        config.spell_max = -1
      end
    end
  end
end