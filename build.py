# Builds the README.md
# Looks for areas between two markers of the form 
#   [//]: # "filename(#hash)?"
# and replaces the text of those areas by the referenced text.

import codecs
import logging
import re

logging.basicConfig(level=20) # info

f = codecs.open("README.md", "r", "utf-8")
readme = f.read()
f.close()

def mergeText( readme, marker, text, mime ):
    beginPos = readme.find(marker)
    if beginPos == -1:
        logging.error("Invalid marker %s" % marker)
        return readme

    endPos = readme.find('[//]: #', beginPos+1)

    if mime == 'm': mime = 'MATLAB'
    elif mime == 'json': mime = 'JSON'
    else: mime = ''

    readme = readme[1:beginPos] + marker + '\n```' + mime + '\n' + text + '\n```\n' + readme[endPos:]
    return readme

def process( readme, marker ):
    logging.info("Processing %s" % marker)

    # marker is of the form
    #   [//]: # "filename"
    m = re.match('.*"(.*)"', marker)
    filename = m.group(1)
    mime = filename[filename.find('.')+1:]

    f = codecs.open('test/' + filename, "r", "utf-8")
    text = f.read()
    f.close()

    return mergeText( readme, marker, text, mime )

markers = re.findall('\[//\]: # ".*"', readme)
# print(markers)

for marker in markers:
    readme = process(readme, marker)

f = codecs.open("README1.md", "w", "utf-8")
f.write(readme)
f.close()