_ = require 'lodash'
React = require 'react'

{DOM} = React

squareness = (item) ->
  Math.abs 1 - item.width / item.height

proximity = (width, height) ->
  (item) ->
    dist = Math.abs(item.width - width) + Math.abs(item.height - height)
    if item.width < width or item.height < height
      dist *= 5

module.exports = React.createFactory React.createClass
  getInitialState: ->
    expanded: true

  render: ->
    nope = ->
      DOM.div
        style:
          display: 'none'

    unless @props.item?.media?.length > 0
      return nope()

    item = @props.item ? {}
    identity = item?.identity ? {}
    image = ""
    imageWidth = 1
    imageHeight = 1

    tileSize = 200
    maxWidth = 400
    maxHeight = 340

    image = _.find item.media, (item) -> item.type == 'photo'
    unless image?.sizes?.length > 0
      return nope()

    sizeSort = _.sortByOrder image.sizes,
      [squareness, proximity(maxWidth, maxHeight)]
      ['desc', 'desc']

    bestFit = sizeSort[0]

    url = bestFit.url
    imageWidth = bestFit.width
    imageHeight = bestFit.height

    if imageWidth > maxWidth
      imageHeight *= maxWidth / imageWidth
      imageWidth = maxWidth
    if imageHeight > maxHeight
      imageWidth *= maxHeight / imageHeight
      imageHeight = maxHeight

    if imageWidth / imageHeight > @props.width / @props.height
      imageWidth *= @props.height / imageHeight
      imageHeight = @props.height
    else
      imageHeight *= @props.width / imageWidth
      imageWidth = @props.width

    DOM.div
      className: 'gallery-item'
      style:
        width: @props.width
        height: @props.height
        margin: '0 4px 4px 0'
    ,
      DOM.div
        className: 'grid-tile-image-holder'
        style:
          backgroundColor: 'rgba(0, 0, 0, 0.2)'
          width: @props.width
          height: @props.height
      ,
        DOM.img
          className: 'gallery-image'
          src: url
          style:
            width: @props.width
            height: @props.height
      # DOM.div
      #   className: 'gallery-caption'
      # ,
      #   DOM.div
      #     className: 'img'
      #   ,
      #     DOM.a
      #       href: "/admin/identity/view/#{identity.guid}"
      #     ,
      #       DOM.img
      #         className: 'activity-item-avatar'
      #         src: '/images/kerplunk/logo_t.png'
      #   DOM.span
      #     className: 'activity-item-author'
      #   ,
      #     DOM.a
      #       href: "/admin/identity/view/#{identity.guid}"
      #     , identity.displayName
      #   DOM.p
      #     className: 'activity-item-text'
      #   , item.message
