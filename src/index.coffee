module.exports = (System) ->
  globals:
    public:
      streamTypes:
        'kerplunk-gallery:gallery':
          description: 'Gallery! (recent photos)'
          sort: 'desc'
      styles:
        'kerplunk-gallery/css/galleryitem.css': ['/admin/dashboard', '/admin/dashboard/**']
