import codecs

f = codecs.open("README.md", "r", "utf-8")
readme = f.read()
f.close()

def merge( readme, sep, path ):
    "This prints a passed string into this function"
    f = codecs.open('%s' % path, "r", "utf-8")
    markup = f.read()
    f.close()
    c = readme.split('[//]: # "%s"' % sep)
    assert( len(c) == 3 )
    c[1] = '\n\n' + markup + '\n\n'
    readme = ('[//]: # "%s"' % sep).join(c)
    return readme

readme = merge(readme, 'ROUNDTRIP', 'build/roundtrip.md')
readme = merge(readme, 'VALIDATION', 'build/validation.md')
readme = merge(readme, 'PARSE', 'build/parse.md')
readme = merge(readme, 'STRINGIFY', 'build/stringify.md')

f = codecs.open("build/README.md", "w", "utf-8")
f.write(readme)
f.close()

exit()