RSpec.describe 'portal/index.html.mustache', :common_view_components, :blacklight_config do
  before do
    assign(:response, response)
    assign(:document_list, response.documents)
    assign(:params, blacklight_params)
    allow(view).to receive(:search_state).and_return(search_state)
    allow(controller).to receive(:search_action_url).and_return('/search')
  end

  let(:api_response) do
    {
      'totalResults': 2_278_183,
      items: api_response_items
    }
  end

  let(:api_response_items) do
    [
      { id: '/abc/123', title: 'Paris in summer' },
      { id: '/abc/124', title: 'Paris in winter' }
    ]
  end

  let(:blacklight_params) { { q: 'paris', per_page: 12 } }
  let(:request_params) { { query: 'paris', rows: 12, start: 1 } }
  let(:response) { Europeana::Blacklight::Response.new(api_response, request_params) }
  let(:search_state) { Blacklight::SearchState.new(blacklight_params, blacklight_config) }

  it 'includes the search terms in the title' do
    render
    expect(rendered).to have_selector('title', text: /#{blacklight_params[:q]}/, visible: false)
  end

  it 'displays the search terms' do
    render
    expect(rendered).to have_selector('li.search-tag', text: /#{blacklight_params[:q]}/)
  end

  describe 'search result for a document' do
    it 'links to the record page with the query and log params' do
      render
      api_response[:items].each_with_index do |item, index|
        id_param = item[:id][1..-1] # omitting leading slash
        log_params = { p: { q: blacklight_params[:q] }, t: 2_278_183, r: index + 1 }
        expect(rendered).to have_link(item[:title], href: document_path(id_param, format: 'html', l: log_params, q: blacklight_params[:q]))
      end
    end

    context 'when title is longer than 225 characters' do
      let(:api_response_items) do
        [{ id: '/abc/123', title: 'abcdefghi ' * 30 }]
      end

      it 'truncates the title' do
        full_title = api_response_items.first[:title]
        truncated_title = truncate(full_title, length: 225, separator: ' ')
        render
        expect(rendered).not_to have_link(full_title)
        expect(rendered).to have_link(truncated_title)
      end
    end
  end

  context 'when within a collection' do
    before(:each) do
      allow(view).to receive(:within_collection?).and_return(true)
      allow(view).to receive(:current_collection).and_return(collection)
      assign(:collection, collection)
    end

    context 'with a default layout' do
      let(:collection) { collections(:grid_layout) }
      it 'sets that default layout' do
        render
        expect(rendered).to have_selector('body.display-grid')
      end
    end

    context 'without a default layout' do
      let(:collection) { collections(:art) }
      it 'defaults layout to list' do
        render
        expect(rendered).not_to have_selector('body.display-grid')
      end
    end
  end
end
