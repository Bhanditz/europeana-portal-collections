require 'rails_helper'

RSpec.describe 'routes for the portal controller', :type => :routing do
  it 'routes GET /search to portal#index' do
    expect(get(ENV['RAILS_RELATIVE_URL_ROOT'] + '/search')).to route_to('portal#index')
  end

  it 'routes GET /record/:id to portal#show' do
    expect(get(ENV['RAILS_RELATIVE_URL_ROOT'] + '/record/abc/123')).to route_to('portal#show', id: 'abc/123')
  end

  it 'routes POST /record/:id/track to portal#track' do
    expect(post(ENV['RAILS_RELATIVE_URL_ROOT'] + '/record/abc/123/track')).to route_to('portal#track', id: 'abc/123')
  end

  it 'routes GET /record/:id/similar to portal#similar' do
    expect(get(ENV['RAILS_RELATIVE_URL_ROOT'] + '/record/abc/123/similar')).to route_to('portal#similar', id: 'abc/123')
  end
end
