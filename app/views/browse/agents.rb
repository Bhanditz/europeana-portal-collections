module Browse
  class Agents < ApplicationView
    def page_title
      mustache[:page_title] ||= begin
        [t('site.browse.agents.title'), site_title].join(' - ')
      end
    end

    def content
      mustache[:content] ||= begin
        {
          title: page_title,
          description: t('site.browse.agents.description'),
          browse_entries: @agents.blank? ? nil : {
            items: browse_entry_items(@agents)
          },
        }
      end
    end

    def head_meta
      mustache[:head_meta] ||= begin
        [
          { meta_name: 'description', content: page_title }
        ] + super
      end
    end
  end
end
