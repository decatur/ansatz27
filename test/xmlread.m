function document = xmlread(filePath)

factory = javaMethod('newInstance', 'javax.xml.parsers.DocumentBuilderFactory');
builder = factory.newDocumentBuilder();

file = javaObject('java.io.File', filePath);
document = builder.parse(file);

end