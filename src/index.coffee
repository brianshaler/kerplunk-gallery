module.exports = (System) ->
  globals:
    public:
      streamTypes:
        'kerplunk-gallery:gallery':
          description: 'Gallery! (recent photos)'
          sort: 'desc'
      css:
        'kerplunk-gallery:galleryItem': 'kerplunk-gallery/css/galleryitem.css'
