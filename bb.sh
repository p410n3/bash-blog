#!/bin/bash

# TODO: Make faster by using more cores / threads via parallel

# Dependencies:
# pandoc, parallel

# Check if output exists. Then delete it if neccesary
[ -d 'output' ] && rm -rf 'output'

# Now create output - fully empty
mkdir 'output' 'output/posts' 'output/img'

# Get all images in output - without any subfolders! This allows us to shorten relative paths in all html files later on and ensure working images
cp $(find images/ -type f) output/img

# Extract top and bottom of template
# Files are now template00 and template01
csplit -f template template.html '/<!--+++-->/' > /dev/null

# Convert all posts from .md to html in the order new to old and put them in posts
ls posts | parallel 'pandoc posts/{}' -o 'output/posts/{.}.html'

# Merge them with the template
ls output/posts | parallel echo $(cat template00) $(cat output/posts/{}) $(cat template01) > output/posts/{}
# todo stop newlines to disappear

# Now make all image links in the posts relative to the img/ folder
# TODO

# Get links to post. The linktext is the first header of said post
_postlinks=$(ls output/posts | sort -r | parallel echo \
    '\<a href=\"posts/{}\"\> \
        $(egrep -m1 -o "<h[0-5].*\/h[0-5]>" "output/posts/{}" | sed "s#</h[0-5]>##g" | sed "s#^.*>##g") \
    \</a\>')

# Merge the index page
echo $(cat template00) '<div class="posts">' $_postlinks '</div>' $(cat template01) >> output/index.html

# Show Finished to the user
echo 'Finished'
exit 0
