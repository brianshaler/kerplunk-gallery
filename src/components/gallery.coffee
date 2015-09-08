_ = require 'lodash'
React = require 'react'

{DOM} = React

squareness = (item) ->
  return 0 unless item?.width > 0 and item.height > 0
  Math.abs 1 - item.width / item.height

getAspectRatio = (item) ->
  image = _.find item.media, (item) -> item.type == 'photo'
  return 1 unless image?.sizes.length > 0
  sorted = _.sortByOrder image.sizes, squareness, 'desc'
  sorted[0].width / sorted[0].height

module.exports = React.createFactory React.createClass
  getDefaultProps: ->
    margin: 4

  getInitialState: ->
    arr = @props.data ? []
    ids = _.pluck arr, '_id'
    items = {}
    aspectRatios = {}
    for item in arr
      items[item._id] = item
      aspectRatios[item._id] = getAspectRatio item
    sortedIds = @getSortedIds items

    items: items
    aspectRatios: aspectRatios
    sortedIds: sortedIds
    latestUpdatedAt: null
    oldestPost: null
    width: 100
    windowWidth: 0
    sizes: []

  componentDidMount: ->
    window.gallery = @
    @refreshLater()
    @onResize()
    window.addEventListener 'resize', @onResize

  componentWillUnmount: ->
    clearTimeout @refreshTimeout if @refreshTimeout
    @refreshTimeout = null
    window.removeEventListener 'resize', @onResize

  refreshLater: ->
    clearTimeout @refreshTimeout if @refreshTimeout
    @refreshTimeout = setTimeout =>
      @refresh()
    , 5000

  onResize: (e) ->
    return unless @isMounted()
    width = @getDOMNode().parentElement.offsetWidth - 40
    return if width == @state.width
    sizes = @getSizes width: width

    @setState
      width: width
      sizes: sizes

  getSizes: (opt = {}) ->
    ids = opt.ids ? @state.sortedIds
    items = opt.items ? @state.items
    aspectRatios = opt.aspectRatios ? @state.aspectRatios
    width = opt.width ? @state.width

    return @state.sizes unless @isMounted()
    # windowWidth = window.innerWidth
    # width = @getDOMNode().parentElement.offsetWidth
    # return if width == @state.width

    maxHeight = width / 4

    newRow = ->
      items: []
      width: 0

    add = (row, item) =>
      items: row.items.concat item
      width: row.width + @props.margin + maxHeight * item.aspectRatio

    rows = []
    row = newRow()
    _.each ids, (_id) ->
      #item = items[id]
      row = add row,
        _id: _id
        aspectRatio: aspectRatios[_id]
      if row.width > width
        height = Math.floor maxHeight * width / row.width
        rows.push _.map row.items, (item) ->
          _id: item._id
          width: Math.floor height * item.aspectRatio
          height: Math.floor height
        row = newRow()

    sizes = _.flatten rows

  getSortedIds: (items = @state.items) ->
    _ items
    .sortBy (item) -> -1 * Date.parse item.postedAt
    .pluck '_id'
    .value()

  refresh: ->
    return unless @isMounted()
    clearTimeout @refreshTimeout if @refreshTimeout
    @refreshTimeout = null
    opt = {}
    url = "/admin/dashboard/stream/#{@props.stream._id}.json"
    if @state.latestUpdatedAt
      opt.updatedSince = @state.latestUpdatedAt
      opt.postedSince = @state.oldestPost

    @props.request.get url, opt, (err, response) =>
      return unless @isMounted()
      if err
        console.log 'error', err
        return @refreshLater()
      items = []
      if response.state.data?.length > 0
        items = response.state.data

      # console.log "received #{items.length} item(s)"
      return unless items.length > 0

      latestUpdatedAt = 0
      oldestPost = 0
      for item in items
        @props.Repository.update item._id, item
        updatedAt = Date.parse item.updatedAt
        postedAt = Date.parse item.postedAt
        latestUpdatedAt = updatedAt if updatedAt > latestUpdatedAt
        oldestPost = postedAt if oldestPost == 0 or postedAt < oldestPost

      newItems = _.filter items, (item) =>
        _id = String item._id
        found = _.find @state.items, (existingItem) ->
          _id = String existingItem._id
        !found
      if newItems.length > 0
        allItems = _.clone @state.items
        newAspect = _.clone @state.aspectRatios
        for item in newItems
          allItems[item._id] = item
          newAspect[item._id] = getAspectRatio item
        sortedIds = @getSortedIds allItems
        sizes = @getSizes
          ids: sortedIds
          items: allItems
          aspectRatios: newAspect

        @setState
          sortedIds: sortedIds
          aspectRatios: newAspect
          sizes: sizes

      if latestUpdatedAt > @state.latestUpdatedAt
        @setState
          latestUpdatedAt: latestUpdatedAt
          oldestPost: if !@state.oldestPost? or oldestPost < @state.oldestPost
            oldestPost
          else
            @state.oldestPost

      @refreshLater()

  render: ->
    GalleryItem = @props.getComponent 'kerplunk-gallery:galleryItem'

    # unless @state.width > 0
    #   return DOM.div style: {display: 'none'}, @state.width

    #activityItems = @state.activityItems

    list = _.map @state.sizes, (item) =>
      GalleryItem _.extend {}, @props, @state,
        key: "activity-item-#{item._id}"
        item: @state.items[item._id]
        width: item.width
        height: item.height
    unless list.length > 0
      list = DOM.div null,
        GalleryItem _.extend {}, @props, @state,
          item: @props.data[0]
        'no items'

    DOM.div
      className: 'activity-item-list'
      style:
        width: @state.width + 8
    ,
      list
      DOM.div className: 'clearfix'
