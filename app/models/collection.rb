class Collection < ActiveRecord::Base
  include HasPublicationStates

  has_and_belongs_to_many :browse_entries

  has_paper_trail

  validates :key, presence: true, uniqueness: true
  validates :api_params, presence: true

  after_save :touch_landing_page

  translates :title, fallbacks_for_empty_translations: true
  accepts_nested_attributes_for :translations, allow_destroy: true

  def to_param
    key
  end

  def api_params_hash
    {}.tap do |hash|
      api_params.split('&').map do |param|
        key, val = param.split('=')
        hash[key] ||= []
        hash[key] << val
      end
    end
  end

  def has_landing_page?
    landing_page.present?
  end

  def landing_page
    @landing_page ||= Page::Landing.find_by_slug(landing_page_slug)
  end

  def landing_page_slug
    key == 'all' ? '' : "collections/#{key}"
  end

  def landing_page_title
    landing_page.present? ? landing_page.title : nil
  end

  def touch_landing_page
    landing_page.touch if landing_page.present?
  end
end
