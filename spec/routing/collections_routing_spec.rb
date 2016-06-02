RSpec.describe 'routes for the collections controller' do
  it 'routes GET /collections to collections#index' do
    expect(get('/collections')).to route_to('collections#index')
  end

  it 'routes GET /collections/:id to collections#show' do
    expect(get('/collections/art')).to route_to('collections#show', id: 'art')
  end

  it 'routes GET /collections/:id/tumblr to collections#tumblr' do
    expect(get('/collections/art/tumblr')).to route_to('collections#tumblr', id: 'art')
  end
end
