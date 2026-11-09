# frozen_string_literal: true

module OpenprojectWikiAPI
  module V1
    module Helpers
      include ::API::Utilities::UrlPropsParsingHelper

      WIKI_TEXT_FORMAT = "common_mark"

      def find_visible_project
        scope = if current_user.admin?
                  Project.all
                else
                  Project.visible(current_user)
                end

        value = params[:project_id].to_s

        if value.match?(/\A\d+\z/)
          scope.find(value)
        else
          scope.find_by!(identifier: value)
        end
      end

      def project_wiki_pages(project)
        WikiPage
          .visible(current_user)
          .where(wiki_id: project.wiki&.id)
          .includes(:parent)
          .order(:title)
      end

      def wiki_page_list_item(page)
        journal = page.last_journal

        {
          id: page.id,
          title: page.title,
          slug: page.slug,
          parent: page.parent ? { id: page.parent.id, title: page.parent.title } : nil,
          version: page.version,
          createdAt: page.created_at,
          updatedAt: journal&.created_at || page.updated_at
        }
      end

      def wiki_page_detail(page)
        journal = page.last_journal

        wiki_page_list_item(page).merge(
          project: {
            id: page.project.id,
            identifier: page.project.identifier,
            name: page.project.name
          },
          text: journal&.data&.text,
          format: WIKI_TEXT_FORMAT
        )
      end

      def find_wiki_page_visible
        WikiPage.visible(current_user).find(params[:id])
      end

      def wiki_user_item(user)
        return nil if user.nil?

        { id: user.id, login: user.login, name: user.name }
      end

      def wiki_journal_item(journal)
        {
          id: journal.id,
          version: journal.version,
          createdAt: journal.created_at,
          author: wiki_user_item(journal.user),
          notes: journal.notes,
          text: journal.data&.text
        }
      end

      def wiki_attachment_item(attachment)
        {
          id: attachment.id,
          filename: attachment.filename,
          filesize: attachment.filesize,
          contentType: attachment.content_type,
          author: wiki_user_item(attachment.author),
          createdAt: attachment.created_at,
          downloadUrl: "/api/v3/attachments/#{attachment.id}/content"
        }
      end

      def paginate_wiki_pages(scope)
        per_page = resolve_page_size(params[:pageSize]) || WikiPage.per_page
        page_number = params[:offset].to_i.positive? ? params[:offset].to_i : 1
        total = scope.count
        paged = per_page.zero? ? scope.none.to_a : scope.offset((page_number - 1) * per_page).limit(per_page).to_a

        {
          _type: "Collection",
          total: total,
          count: paged.count,
          pageSize: per_page,
          offset: page_number,
          _embedded: {
            wikiPages: paged.map { |page| wiki_page_list_item(page) }
          }
        }
      end
    end
  end
end
