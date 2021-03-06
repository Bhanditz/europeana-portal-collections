# frozen_string_literal: true

require 'support/shared_examples/jobs'

shared_examples 'provider record count caching job' do
  it_behaves_like 'a caching job'
  it_behaves_like 'an API requesting job'

  it 'should write provider record counts to cache' do
    subject.perform(*args)
    cached = Rails.cache.fetch(cache_key)
    expect(cached).to be_a(Array)
    cached.each do |provider|
      expect(provider).to include(:text)
      expect(provider).to include(:count)
    end
  end

  it 'should queue data provider jobs' do
    expect { subject.perform(*args) }.to have_enqueued_job(Cache::RecordCounts::DataProvidersJob).at_least(:once)
  end
end

RSpec.describe Cache::RecordCounts::ProvidersJob do
  context 'without collection ID' do
    let(:cache_key) { 'browse/sources/providers' }
    let(:args) {}
    let(:api_request) { an_api_search_request }

    it_behaves_like 'provider record count caching job'
  end

  context 'with collection ID' do
    let(:collection) { Collection.published.first }
    let(:cache_key) { "browse/sources/providers/#{collection.key}" }
    let(:args) { collection.id }
    let(:api_request) { an_api_collection_search_request(collection.id) }

    it_behaves_like 'provider record count caching job'
  end
end
