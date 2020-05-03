#!/bin/bash

# Dependencies:
# pandoc, parallel

# Check if output exists. Then delete it if neccesary
[ -d 'output' ] && rm -rf 'output'

# Now create output folders
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
ls output/pages | parallel echo '"$(cat template00) <section> $(cat output/pages/{}) </section> $(cat template01)" > output/pages/{}'
ls output/posts | parallel echo '"$(cat template00) <article> $(cat output/posts/{}) </article> $(cat template01)" > output/posts/{}'

# Now make all image links in the files relative to the img/ folder

# Make a function for later use with parallel
function fix_img_links {
    # $1 is gonna be the full path to the html file we are fixing atm

    # Using awk, we get all images that are files in the html. 
    # We then locate everything in front of the images name from it and replace it with our fixed path
    _paths_to_fix=$(awk '/<img src=.*\/>/ && ( /jpg/ || /jpeg/ || /png/ || /gif/ ) && !/http/  { print $2; }' $1 | parallel echo | grep -o '^.*/')

    # Now replace paths with our path
    echo "$_paths_to_fix" | parallel echo "lol {}"
}
# export it in to the environment
export -f fix_img_links

ls output/pages | parallel fix_img_links "output/pages/{}"
ls output/posts | parallel fix_img_links "output/posts/{}"
exit 0

# The following function generates the links to stuff like pages and posts. 

# The linktext is the actual text inside the first header inside of href
# This way, the linktext and the headline of the article / page are the same. No stuff like YAML front matter needed

# $1 is the folder in output/ we gonna work with. So either 'pages' or 'posts'
# $2 is the name of the file itself. This gets passed from parallel as seen a couple lines down

function generate_links {
    echo "<a href=\"$1/$2\"> \
        $(grep -Po "<h[0-5].*?\/h[0-5]>" "output/$1/$2" | head -n 1 | sed "s#</h[0-5]>##g" | sed "s#^.*>##g") \
    </a>"
}
# export it in to the environment
export -f generate_links

# Now generate the links
_postlinks=$(ls output/posts | sort -r | parallel generate_links 'posts')
_pagelinks=$(ls output/pages | parallel generate_links 'pages')

# Merge all the stuff we have into the index page
echo $(cat template00) \
    '<div class="pages">' \
        $_pagelinks \
    '</div>' \
    '<div class="posts">' \
        $_postlinks \
    '</div>' \
    $(cat template01) > output/index.html

# Show Finished to the user
echo 'Finished'
exit 0
