# frozen_string_literal: true

require_relative "helpers"
require_relative "wiki_pages_journals_api"

module OpenprojectWikiAPI
  module V1
    class WikiPagesAPI < ::API::OpenProjectAPI
      helpers ::OpenprojectWikiAPI::V1::Helpers

      resources :wiki_pages do
        route_param :id, type: Integer, desc: "Wiki page ID" do
          mount ::OpenprojectWikiAPI::V1::WikiPagesJournalsAPI

          get do
            page = WikiPage.visible(current_user).find(params[:id])

            wiki_page_detail(page)
          end

          params do
            optional :title,
                     type: String
            optional :text,
                     type: String,
                     desc: "Page content (CommonMark markdown); changing it creates a new journal version"
            optional :parent_id,
                     type: Integer,
                     desc: "ID of the parent wiki page (explicit null is rejected by Grape 3.x; detaching is not supported via API)"
            optional :journal_notes,
                     type: String,
                     desc: "Notes stored on the new journal entry"
            optional :lock_version,
                     type: Integer,
                     desc: "Current lock version for optimistic locking; a stale value results in 409"
          end
          patch do
            page = WikiPage.visible(current_user).find(params[:id])
            authorize_in_project(:edit_wiki_pages, project: page.project)

            attributes = declared(params, include_missing: false)
                           .symbolize_keys
                           .slice(:title, :text, :parent_id, :journal_notes, :lock_version)

            call = ::WikiPages::UpdateService
                     .new(user: current_user, model: page)
                     .call(attributes)

            if call.success?
              wiki_page_detail(call.result)
            else
              raise ::API::Errors::ErrorBase.create_and_merge_errors(call.errors)
            end
          end

          delete do
            page = WikiPage.visible(current_user).find(params[:id])
            authorize_in_project(:edit_wiki_pages, project: page.project)

            page.destroy!

            status 204
          end
        end
      end
    end
  end
end
