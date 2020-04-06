#!/bin/bash

# TODO: Make faster by using more cores / threads via parallel

# Dependencies:
# pandoc, parallel

# Check if output exists. Then delete it if neccesary
[ -d 'output' ] && rm -rf 'output'

# Now create output - fully empty
mkdir 'output' 'output/posts' 'output/pages' 'output/img'

# Get all images in output - without any subfolders! This allows us to shorten relative paths in all html files later on and ensure working images
cp $(find images/ -type f) output/img

# Extract top and bottom of template
# Files are now template00 and template01
csplit -f template template.html '/<!--+++-->/' > /dev/null

# Convert all pages and posts from .md to html and put them in the output folder
ls pages | parallel 'pandoc pages/{}' -o 'output/pages/{.}.html'
ls posts | parallel 'pandoc posts/{}' -o 'output/posts/{.}.html'

# Merge them with the template
ls output/posts | parallel echo '"$(cat template00) <article> $(cat output/posts/{}) </article> $(cat template01)" > output/posts/{}'
# todo stop newlines to disappear

# Now make all image links in the posts relative to the img/ folder
# TODO

# This function generates the links to stuff like pages and posts. 

# The linktext is the actual text inside the first header inside of href
# This way, the linktext and the headline of the article / page are the same. No stuff like YAML front matter needed
function generate_links {
    echo "<a href=\"$1/$2\"> \
        $(grep -Po "<h[0-5].*?\/h[0-5]>" "output/$1/$2" | head -n 1 | sed "s#</h[0-5]>##g" | sed "s#^.*>##g") \
    </a>"
}
export -f generate_links

_postlinks=$(ls output/posts | sort -r | parallel generate_links 'posts')
_pagelinks=$(ls output/pages | parallel generate_links 'pages')

# Merge the index page
echo $(cat template00) \
    '<div class="pages">' \
        $_pagelinks \
    '</div>' \
    '<div class="posts">' \
        $_postlinks \
    '</div>' \
    $(cat template01) >> output/index.html

# Show Finished to the user
echo 'Finished'
exit 0
