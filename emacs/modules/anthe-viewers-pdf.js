// What anthe-viewers.el reads of a PDF shown in zathura, with MuPDF:
//   mutool run anthe-viewers-pdf.js links FILE PAGE
//     the links of a page (PAGE from 1), "LINK URI", then "TEXT" and its text
//     (SPC s l);
//   mutool run anthe-viewers-pdf.js outline FILE
//     the outline, "LEVEL<TAB>PAGE<TAB>TITLE" (o and SPC m o);
//   mutool run anthe-viewers-pdf.js text FILE
//     each line of text, "PAGE<TAB>LINE" (SPC m s).
var command = scriptArgs[0];
var doc = Document.openDocument(scriptArgs[1]);

function outline(items, level) {
  for (var i = 0; i < items.length; i++) {
    var page = -1;
    try { page = doc.resolveLink(items[i].uri); } catch (e) {}
    print(level + "\t" + (page + 1) + "\t" + items[i].title.replace(/\s+/g, " "));
    if (items[i].down) outline(items[i].down, level + 1);
  }
}

if (command == "links") {
  var page = doc.loadPage(parseInt(scriptArgs[2]) - 1);
  var links = page.getLinks();
  for (var i = 0; i < links.length; i++)
    if (links[i].isExternal()) print("LINK " + links[i].getURI());
  print("TEXT");
  print(page.toStructuredText().asText());
} else if (command == "outline") {
  outline(doc.loadOutline() || [], 1);
} else if (command == "text") {
  for (var n = 0; n < doc.countPages(); n++) {
    var lines = doc.loadPage(n).toStructuredText().asText().split("\n");
    for (var j = 0; j < lines.length; j++)
      if (/\S/.test(lines[j])) print((n + 1) + "\t" + lines[j]);
  }
}
