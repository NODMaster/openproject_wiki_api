# frozen_string_literal: true

require_relative "helpers"

module OpenprojectWikiAPI
  module V1
    class WikiPagesJournalsAPI < ::API::OpenProjectAPI
      helpers ::OpenprojectWikiAPI::V1::Helpers

      namespace :journals do
        get do
          page = find_wiki_page_visible

          page.journals.order(version: :asc).map { |journal| wiki_journal_item(journal) }
        end

        namespace :diff do
          params do
            optional :from,
                     type: Integer,
                     desc: "Version to compare from (defaults to the version before `to`)"
            optional :to,
                     type: Integer,
                     desc: "Version to compare to (defaults to the latest version)"
          end
          get do
            page = find_wiki_page_visible

            diff = page.diff(params[:to], params[:from])
            raise ::API::Errors::NotFound.new if diff.nil?

            {
              from: diff.content_from.version,
              to: diff.content_to.version,
              diff: ::OpenProject::HtmlDiff.from_markdown(
                diff.content_from.data.text.to_s,
                diff.content_to.data.text.to_s
              ),
              textFrom: diff.content_from.data.text,
              textTo: diff.content_to.data.text
            }
          end
        end
      end

      namespace :attachments do
        get do
          page = find_wiki_page_visible

          page.attachments.map { |attachment| wiki_attachment_item(attachment) }
        end
      end
    end
  end
end
