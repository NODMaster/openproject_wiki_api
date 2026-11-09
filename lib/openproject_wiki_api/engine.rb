# frozen_string_literal: true

require "open_project/plugins"

module OpenprojectWikiAPI
  class Engine < ::Rails::Engine
    engine_name :openproject_wiki_api

    include OpenProject::Plugins::ActsAsOpEngine

    register "openproject_wiki_api", author_url: "https://github.com/NODMaster" do
      name        "Wiki REST API access"
      author      "NODMaster, Kimi AI"
      version     "0.4.0"
      description "REST API wiki"
      author_url  "https://github.com/NODMaster"
    end

    add_api_endpoint "API::V3::Root" do
      require_relative "v1/api"
      mount ::OpenprojectWikiAPI::V1::API
    end
  end
end
