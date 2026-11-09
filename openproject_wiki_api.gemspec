Gem::Specification.new do |spec|
  spec.name          = "openproject_wiki_api"
  spec.version       = "0.4.0"
  spec.authors       = ["NODMaster", "Kimi AI"]
  spec.email         = ["nodmaster@mail.ru"]
  spec.metadata["author_url"] = "https://github.com/NODMaster"
  spec.summary       = "Wiki REST API for OpenProject"
  spec.description   = "Full REST API access to wiki pages: list, content, " \
                       "create/update/delete, version history (journals, diff) and attachments."
  spec.license       = "GPL-3.0"
  spec.files         = Dir["lib/**/*"]
end
