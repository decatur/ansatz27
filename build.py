import codecs
import xml.etree.ElementTree as ET
import logging

logging.basicConfig(level=20) # info

f = codecs.open("README.md", "r", "utf-8")
readme = f.read()
f.close()

#def getElementByDescription( root, description ):
#    return root.find( ".//*[description='%s']" % description )

def mergeText( readme, sep, text ):
    c = readme.split('[//]: # "%s"' % sep)
    if len(c) != 3:
        #logging.warning("Skip %s" % sep)
        return readme

    logging.info("Replacing %s" % sep)
    c[1] = text + '\n'
    readme = ('[//]: # "%s"' % sep).join(c)
    return readme

def mergeElement( readme, sep, element ):
    text = ''
    for child in element:
        if child.text == None:
            continue
        elif child.tag == 'matlab':
            text = text + '\n*MATLAB*\n```MATLAB\n' + child.text + '\n```'
        elif child.tag == 'schema':
            text = text + '\n*Schema*\n```JSON\n' + child.text + '\n```'
        elif child.tag == 'json':
            text = text + '\n*JSON*\n```JSON\n' + child.text + '\n```'
        elif child.tag == 'errors':
            text = text + '\n*Errors*\n```MATLAB\n' + child.text + '\n```'

    return mergeText( readme, sep, text )

def processTests( readme, path ):
    tree = ET.parse(path)
    root = tree.getroot()

    for child in root:
        #if child.attrib.get('readme', 'false') == 'true':
        readme = mergeElement(readme, child.find('description').text, child)

    return readme

def processFile( readme, sep ):
    f = codecs.open(sep, "r", "utf-8")
    code = f.read()
    f.close()
    return mergeText( readme, sep, '\n```MATLAB\n' + code + '\n```' )

readme = processTests(readme, 'test/testRoundtrip.xml')
readme = processTests(readme, 'test/testParse.xml')
readme = processTests(readme, 'test/testValidation.xml')

readme = processFile(readme, 'test/testErrorHandling.m')
readme = processFile(readme, 'test/testUsage.m')

f = codecs.open("README1.md", "w", "utf-8")
f.write(readme)
f.close()