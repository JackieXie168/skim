rst2html = /System/Library/Frameworks/Python.framework/Versions/2.3/bin/rst2html.py
rst2latex = /System/Library/Frameworks/Python.framework/Versions/2.3/bin/rst2latex.py

all: applehelp html pdf

html: 
	${rst2html} Manual.txt --stylesheet=bibdeskManual.css

applehelp:
	${rst2html} Manual.txt --stylesheet=bibdeskManual.css

pdf:
	echo "nothing"