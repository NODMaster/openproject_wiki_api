# frozen_string_literal: true

require_relative "helpers"
require_relative "projects_wiki_pages_api"
require_relative "wiki_pages_api"

module OpenprojectWikiAPI
  module V1
    class API < ::API::OpenProjectAPI
      helpers ::OpenprojectWikiAPI::V1::Helpers

      resources :wiki_api do
        get :health do
          {
            status: "ok",
            plugin: "openproject_wiki_api",
            version: "0.4.0"
          }
        end

        mount ::OpenprojectWikiAPI::V1::ProjectsWikiPagesAPI
        mount ::OpenprojectWikiAPI::V1::WikiPagesAPI
      end
    end
  end
end
