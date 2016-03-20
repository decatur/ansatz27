import codecs
import xml.etree.ElementTree as ET
import logging

logging.basicConfig(level=20) # info

f = codecs.open("README.md", "r", "utf-8")
readme = f.read()
f.close()

def getElementByDescription( root, description ):
    return root.find( ".//*[description='%s']" % description )

def merge( readme, sep, element ):
    c = readme.split('[//]: # "%s"' % sep)
    if len(c) != 3:
        #logging.warning("Skip %s" % sep)
        return readme

    logging.info("Replacing %s" % sep)
    c[1] = ''
    for child in element:
        if child.tag == 'matlab':
            c[1] = c[1] + '\n*MATLAB*\n```MATLAB\n' + child.text + '\n```'
        elif child.tag == 'schema':
            c[1] = c[1] + '\n*Schema*\n```JSON\n' + child.text + '\n```'
        elif child.tag == 'json':
            c[1] = c[1] + '\n*JSON*\n```JSON\n' + child.text + '\n```'
        elif child.tag == 'errors':
            c[1] = c[1] + '\n```MATLAB\n' + child.text + '\n```'

    c[1] = c[1] + '\n\n'
    readme = ('[//]: # "%s"' % sep).join(c)
    return readme

def processTests( readme, path ):
    tree = ET.parse(path)
    root = tree.getroot()

    for child in root:
        #if child.attrib.get('readme', 'false') == 'true':
        readme = merge(readme, child.find('description').text, child)

    return readme

readme = processTests(readme, 'test/testRoundtrip.xml')
readme = processTests(readme, 'test/testParse.xml')
readme = processTests(readme, 'test/testValidation.xml')

f = codecs.open("README1.md", "w", "utf-8")
f.write(readme)
f.close()