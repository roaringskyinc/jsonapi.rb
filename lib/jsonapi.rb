require 'jsonapi/errors'
require 'jsonapi/fetching'
require 'jsonapi/filtering'
require 'jsonapi/pagination'
require 'jsonapi/deserialization'
require 'jsonapi/rails'
require 'jsonapi/version'
require 'ransack-mongoid/lib/ransack/mongoid/version'

# JSON:API
module JSONAPI
  # JSONAPI media type.
  MEDIA_TYPE = 'application/vnd.api+json'.freeze
end
