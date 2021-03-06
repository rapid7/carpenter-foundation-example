
define [], ->

  #
  # Used for collections that call out to the network
  #
  # @event change:numSelected
  #   Emitted when the number of selected records in the collection changes.
  #   @param numSelected [Number] the number of selected records
  # @event remove:multiple
  #   Emitted when several models are simultaneously removed from the collection.
  #   @param removedIDs [Array<Number>] the IDs of the removed records
  # @event remove:multiple:complete
  #   Emitted after several models have successfully been removed from the collection.
  class AjaxPaginatedCollection extends Backbone.Paginator.requestPager
    server_api:
    # so that TableResponder wraps the collection in a metadata hash
      ui: 1

      sort_by: null

      format: 'json'

      per_page: -> this.perPage

      page: -> this.currentPage

    # @param sortColumn [String] the unique attribute of the column to sort by
    # @param sortDirection [String] (asc|desc)
    # @param renamedSortColumn [String] a (possibly non-unique) to sort by instead
    setSort: (@sortColumn, @sortDirection, @renamedSortColumn) ->
      @updateSortKey()
      this.fetch reset: true

    #
    # Run a search of the models in the table based on the state of the {Filter}.
    #
    # @param filter [Filter] the table's current filter
    setSearch: (filter) ->
      @server_api.search = filter.attributes
      this.fetch
        reset: true
        error: (model, response, options) =>
          @displayErrorMessage(response?.responseJSON?.message)

    displayErrorMessage: (message) ->
      @carpenter.command 'flash:display',
        title:   'Error in search'
        style:   'error'
        message: message || 'There is an error in your search terms.'

    # Remembers the sort options for the next API call
    updateSortKey: ->
      col = @renamedSortColumn || @sortColumn
      @server_api.sort_by = "#{col} #{@sortDirection}"

    parse: (results) ->
      this.totalRecords = results.total_count
      results.collection

    sort: ->

    initialize: (models, options) ->
      @numSelected = 0
      @server_api.search = {}

      super(models, options)

  #
  # Used for static collections
  #
  # @event change:numSelected
  #   Emitted when the number of selected records in the collection changes.
  #   @param numSelected [Number] the number of selected records
  # @event remove:multiple
  #   Emitted when several models are simultaneously removed from the collection.
  #   @param removedIDs [Array<Number>] the IDs of the removed records
  # @event remove:multiple:complete
  #   Emitted after several models have successfully been removed from the collection.
  class StaticPaginatedCollection extends Backbone.Paginator.clientPager

  #
  # Static method for building a PaginatedCollection from an existing
  # Backbone collection. That way consumers of the table API never have
  # to deal with PaginatedCollection themselves.
  #
  # @param Collection [Backbone.Collection] a Collection to wrap
  # @param opts [Object] the options hash
  # @option opts :static [Boolean] use a static collection
  # @return [Function] subclass of PaginatedCollection with the
  #   relevant attributes set
  #
  CreatePaginatedCollectionClass = (collection, opts={}) ->

    superclass = if opts.static
      StaticPaginatedCollection
    else
      AjaxPaginatedCollection

    WrappedCollection = superclass.extend

      model: collection.constructor::model || collection.model

      url: _.result(collection, 'url')

      paginator_core:

      # the type of the request (GET by default)
        type: 'GET'

      # the type of reply (jsonp by default)
        dataType: 'json'

      paginator_ui:

      # the first page we allow anyone to access
        firstPage: opts.firstPage || 1

      # keeps track of the current page of the collection
        currentPage: opts.currentPage || 1

      # number of rows to render per page
        perPage: opts.perPage || 20

    #
    # Update the count of selected records, and fire an event.
    #
    # @param numSelected [Number] the number of currently selected records
      updateNumSelected: (numSelected) ->
        @numSelected = numSelected
        @trigger 'change:numSelected'

    #
    # Remove multiple models from this collection simultaneously, and trigger a
    # custom event. Useful when you want to bind to a 'several things have been
    # removed' event, rather than to each 'remove' event on the collection
    # individually.
    #
    # @param models [Model] an array of models to be removed from this
    #   collection
    #
    # @return [void]
      removeMultiple: (models) ->
        selectedIDs = models.pluck 'id'
        @trigger 'remove:multiple', selectedIDs

    # mix in methods from the original collection instance's class
    for k, v of collection.constructor.prototype
      WrappedCollection.prototype[k] ||= v

    # return the wrapped collection to the user
    WrappedCollection
