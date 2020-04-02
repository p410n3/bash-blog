#!/bin/bash

# Dependencies:
# pandoc, parallel

# Check if output exists. If not, create it
[ -d 'output' ] || mkdir 'output'

# Extract top and bottom of template
# Files are now template00 and template01
csplit -f template template.html '/+++/' > /dev/null

# Convert all posts from .md to html in the order new to old
_posts=$(ls posts | sort -r | parallel 'pandoc posts/{}' | parallel 'echo \<div\>{}\<\/div\>')

# Merge that stuff
echo $(cat template00) $_posts $(cat template01) >> output/index.html

# Show Finished to the user
echo 'Finished'
exit 0
