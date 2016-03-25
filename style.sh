mkdir -p disk
bower update && bower install
lessc less/style.less disk/static/css/style.css --source-map-map-inline --strict-imports 
