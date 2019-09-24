require 'active_support/inflector'

module JSONAPI
  # Helpers to transform a JSON API document, containing a single data object,
  # into a hash that can be used to create an [ActiveRecord::Base] instance.
  #
  # Initial version from the `active_model_serializers` support for JSONAPI.
  module Deserialization
    private
    # Returns a transformed dictionary following [ActiveRecord::Base] specs
    #
    # @param [Hash|ActionController::Parameters] document
    # @param [Hash] options
    #   only: Array of symbols of whitelisted fields.
    #   except: Array of symbols of blacklisted fields.
    #   polymorphic: Array of symbols of polymorphic fields.
    # @return [Hash]
    def jsonapi_deserialize(document)

      # Optional fields, if present, convert to snake/symbol
      # data - (if present, flatten it accordingly to jsonapi spec)
      # include
      # fields
      # filter
      # sort
      # page
      # platform

      # Duplicate document and convert to JSON
      if document.is_a?(ActionController::Parameters)
        primary_data = document.dup.as_json
      elsif document.is_a?(Hash)
        primary_data = document.as_json.deep_dup
      else
        return {}
      end

      # This is the hash that is going to be returned
      parsed = {}
      parsed['include'] = primary_data['include'] if primary_data['include']
      parsed['fields'] = primary_data['fields'] if primary_data['fields']
      parsed['filter'] = primary_data['filter'] if primary_data['filter']
      parsed['sort'] = primary_data['sort'] if primary_data['sort']
      parsed['page'] = primary_data['page'] if primary_data['page']
      parsed['platform'] = primary_data['platform'] if primary_data['platform']

      # Convert primary_data to snake_case
      _primary_data = primary_data.deep_transform_keys(&:underscore)

      if _primary_data['data']
        relationships = _primary_data['data']['relationships'] || {}
        parsed['id'] = _primary_data['id'] if _primary_data['id']

        # Map _primary_data['data']['attributes'] to parsed hash
        if _primary_data['data']['attributes'].respond_to? :each
          _primary_data['data']['attributes'].each do |key, val|
            parsed[key] = val
          end
        end

        relationships.map do |assoc_name, assoc_data|
          assoc_data = (assoc_data || {})['data'] || {}
          rel_name = ActiveSupport::Inflector.singularize(assoc_name)

          if assoc_data.is_a?(Array)
            parsed["#{rel_name}_ids"] = assoc_data.map { |ri| ri['id'] }.compact
            next
          end

          parsed["#{rel_name}_id"] = assoc_data['id']
        end
      end

      # Convert to symbols before returning to client
      parsed.deep_transform_keys!(&:to_sym)
    end
  end
end
