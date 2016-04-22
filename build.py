import codecs
import xml.etree.ElementTree as ET
import logging
import textwrap
import re

logging.basicConfig(level=20) # info

f = codecs.open("README.md", "r", "utf-8")
readme = f.read()
f.close()

#def getElementByDescription( root, description ):
#    return root.find( ".//*[description='%s']" % description )

def mergeText( readme, sep, text ):
    c = readme.split('[//]: # "%s"' % sep)
    if len(c) != 3:
        logging.error("Invalid separator %s" % sep)
        return readme

    c[1] = text + '\n'
    readme = ('[//]: # "%s"' % sep).join(c)
    return readme

def mergeElement( readme, sep, element ):
    text = ''
    for child in element:
        if child.text == None:
            continue

        ct = textwrap.dedent(child.text)
        if child.tag == 'matlab':
            text = text + '\n*MATLAB*\n```MATLAB\n' + ct + '\n```'
        elif child.tag == 'schema':
            text = text + '\n*Schema*\n```JSON\n' + ct + '\n```'
        elif child.tag == 'json':
            text = text + '\n*JSON*\n```JSON\n' + ct + '\n```'
        elif child.tag == 'errors':
            text = text + '\n*Errors*\n```MATLAB\n' + ct + '\n```'

    return mergeText( readme, sep, text )

def process( readme, sep ):
    logging.info("Processing %s" % sep)

    # sep is of the form
    #   [//]: # "filename(#hash)?"
    m = re.match('.*"(.*)"', sep)
    sep = m.group(1)
    parts = sep.split('#')

    if len(parts) == 1:
        f = codecs.open('test/' + sep, "r", "utf-8")
        code = f.read()
        f.close()
        return mergeText( readme, sep, '\n```MATLAB\n' + code + '\n```' )
    else:
        testElem = xmlRoots[parts[0]].find( ".//*[description='%s']" % parts[1] )
        readme = mergeElement(readme, sep, testElem)

    return readme

xmlRoots = dict()
xmlRoots['testRoundtrip.xml'] = ET.parse('test/testRoundtrip.xml').getroot()
xmlRoots['testParse.xml'] = ET.parse('test/testParse.xml').getroot()
xmlRoots['testValidation.xml'] = ET.parse('test/testValidation.xml').getroot()

seps = re.findall('\[//\]: # ".*"', readme)
# print(seps)

for idx, sep in enumerate(seps):
    if idx%2 == 0:
        readme = process(readme, sep)

f = codecs.open("README1.md", "w", "utf-8")
f.write(readme)
f.close()