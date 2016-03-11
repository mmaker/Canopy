mkdir -p disk
bower install
lessc -x less/style.less disk/static/css/style.css
