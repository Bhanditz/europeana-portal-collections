# frozen_string_literal: true

RSpec.describe ProJsonApiConsumer do
  let(:controller_class) do
    Class.new(ApplicationController) do
      include ProJsonApiConsumer
    end
  end

  let(:controller_params) { {} }
  let(:controller_instance) { controller_class.new }

  subject { controller_instance }

  before do
    allow(controller_instance).to receive(:params) { controller_params }
  end

  describe '#pro_json_api_theme_filters_from_collections' do
    subject { controller_class.new.send(:pro_json_api_theme_filters_from_collections) }

    it 'includes whitelisted collections' do
      Collection.where(key: %w(fashion world-war-I)).each do |collection|
        key = collection.key.downcase
        expect(subject).to have_key(key.to_sym)
        expect(subject[key.to_sym]).to eq(filter: "culturelover-#{key}", label: collection.landing_page.title)
      end
    end

    # it 'includes all topics' do
    #   Topic.all.each do |topic|
    #     expect(subject).to have_key(topic.slug.to_sym)
    #     expect(subject[topic.slug.to_sym]).to eq(filter: "culturelover-#{topic.slug}", label: topic.label)
    #   end
    # end
  end
end
