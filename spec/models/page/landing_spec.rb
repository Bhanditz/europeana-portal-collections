RSpec.describe Page::Landing do
  it { is_expected.to belong_to(:hero_image) }
  it { is_expected.to belong_to(:collection) }
  it { is_expected.to have_many(:credits) }
  it { is_expected.to have_many(:social_media) }
  it { is_expected.to have_many(:promotions) }

  it { is_expected.to accept_nested_attributes_for(:hero_image) }
  it { is_expected.to accept_nested_attributes_for(:credits) }
  it { is_expected.to accept_nested_attributes_for(:social_media) }
  it { is_expected.to accept_nested_attributes_for(:promotions) }
  it { is_expected.to accept_nested_attributes_for(:browse_entries) }

  it { is_expected.to respond_to(:newsletter_url) }

  it { is_expected.to delegate_method(:file).to(:hero_image).with_prefix(true) }

  it { is_expected.to validate_inclusion_of(:settings_layout_type).in_array(%w(default browse)) }
  it { is_expected.to validate_presence_of(:collection) }
  it { is_expected.to validate_uniqueness_of(:collection) }

  describe 'modules' do
    subject { described_class }
    it { is_expected.to include(PaperTrail::Model::InstanceMethods) }
  end

  describe 'creation' do
    subject { described_class.new }

    context 'when it is the all collection' do
      it 'should set the slug' do
        subject.collection = collections(:all)
        subject.run_callbacks :create
        expect(subject.slug).to eq('')
      end
    end

    context 'when it is a thematic collection' do
      it 'should set the slug' do
        subject.collection = collections(:music)
        subject.run_callbacks :create
        expect(subject.slug).to eq('collections/music')
      end
    end
  end

  describe '#set_slug' do
    let(:page) { pages(:music_collection) }
    context 'when the slug is empty' do
      before do
        page.slug = nil
      end
      it 'should set the slug' do
        page.send(:set_slug)
        expect(page.slug).to eq('collections/music')
      end
    end
  end
end
