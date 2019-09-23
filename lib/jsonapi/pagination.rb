module JSONAPI
  # Pagination support
  module Pagination
    private
    # Default number of items per page.
    JSONAPI_PAGE_SIZE = 30

    # Applies pagination to a set of resources
    #
    # Ex.: `GET /resource?page[number]=2&page[size]=10`
    #
    # @return [ActiveRecord::Base] a collection of resources
    def jsonapi_paginate(resources)
      @page_length = resources.size ? resources.size : self.class.const_get(:JSONAPI_PAGE_SIZE).to_i
      offset, limit, _ = jsonapi_pagination_params

      # If resources is a collection, only subset resources if the size of the collection is greater than the step size
      if resources.respond_to?(:size)
        if resources.size > limit
          resources = subset(resources, offset, limit)
        end
      else
        resources = subset(resources, offset, limit)
      end

      block_given? ? yield(resources) : resources
    end

    def subset(resources, offset, limit)
      if resources.respond_to?(:offset)
        return resources.offset(offset).limit(limit)
      else
        return resources[(offset)..(offset + limit)]
      end
    end

    # Generates the pagination links
    #
    # @return [Array]
    def jsonapi_pagination(resources)
      links = { self: request.base_url + request.original_fullpath }
      pagination = jsonapi_pagination_meta(resources)

      return links if pagination.blank?

      original_params = params.except(
        *request.path_parameters.keys.map(&:to_s)
      ).to_unsafe_h.with_indifferent_access

      original_params[:page] ||= {}
      original_url = request.base_url + request.path + '?'

      pagination.each do |page_name, number|
        original_params[:page][:number] = number
        links[page_name] = original_url + CGI.unescape(
          original_params.to_query
        )
      end

      links
    end

    # Generates pagination numbers
    #
    # @return [Hash] with the first, previous, next, current, last page numbers
    def jsonapi_pagination_meta(resources)
      return {} unless JSONAPI::Rails.is_collection?(resources)

      _, limit, page = jsonapi_pagination_params

      numbers = { current: page }

      if resources.respond_to?(:unscope)
        total = resources.unscope(:limit, :offset).count()
      else
        total = resources.size
      end

      last_page = [1, (total.to_f / limit).ceil].max

      if page > 1
        numbers[:first] = 1
        numbers[:prev] = page - 1
      end

      if page < last_page
        numbers[:next] = page + 1
        numbers[:last] = last_page
      end

      numbers
    end

    # Extracts the pagination params
    #
    # @return [Array] with the offset, limit and the current page number
    def jsonapi_pagination_params
      def_per_page = @page_length

      pagination = params[:page].try(:slice, :number, :size) || {}
      per_page = pagination[:size].to_f.to_i
      per_page = def_per_page if per_page > def_per_page || per_page < 1
      num = [1, pagination[:number].to_f.to_i].max

      [(num - 1) * per_page, per_page, num]
    end
  end
end
