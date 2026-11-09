# frozen_string_literal: true

require_relative "helpers"

module OpenprojectWikiAPI
  module V1
    class ProjectsWikiPagesAPI < ::API::OpenProjectAPI
      helpers ::OpenprojectWikiAPI::V1::Helpers

      resources :projects do
        route_param :project_id do
          after_validation do
            @project = find_visible_project
          end

          namespace :wiki_pages do
            params do
              optional :offset,
                       type: Integer,
                       default: 1,
                       desc: "Page number (1-based), following the API v3 offset semantics"
              optional :pageSize,
                       type: Integer,
                       default: 25,
                       desc: "Number of items per page; -1 resolves to the configured maximum"
            end
            get do
              authorize_in_project(:view_wiki_pages, project: @project)

              paginate_wiki_pages(project_wiki_pages(@project))
            end

            params do
              requires :title,
                       type: String,
                       desc: "Wiki page title (the slug/permalink is derived from it)"
              optional :text,
                       type: String,
                       desc: "Page content (CommonMark markdown)"
              optional :parent_id,
                       type: Integer,
                       desc: "ID of the parent wiki page"
              optional :journal_notes,
                       type: String,
                       desc: "Notes stored on the initial journal entry"
            end
            post do
              authorize_in_project(:edit_wiki_pages, project: @project)

              attributes = declared(params, include_missing: false)
                             .symbolize_keys
                             .slice(:title, :text, :parent_id, :journal_notes)

              call = ::WikiPages::CreateService
                       .new(user: current_user)
                       .call(attributes.merge(wiki: @project.wiki))

              if call.success?
                status :created
                wiki_page_detail(call.result)
              else
                raise ::API::Errors::ErrorBase.create_and_merge_errors(call.errors)
              end
            end

            route_param :slug, desc: "Wiki page slug/permalink" do
              get do
                authorize_in_project(:view_wiki_pages, project: @project)

                page = @project.wiki&.find_page(params[:slug])
                raise ::API::Errors::NotFound.new if page.nil?

                wiki_page_detail(page)
              end
            end
          end
        end
      end
    end
  end
end
