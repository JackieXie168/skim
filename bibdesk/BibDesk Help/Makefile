texi2html = texi2html
#makeinfo

INPUT = bibdesk.texi

all: applehelp html pdf

# use the longer one for xcode.
# NOTE:: must be done after the copy resources build phase.
#DEST = .
DEST = ${BUILD_DIR}/${UNLOCALIZED_RESOURCES_FOLDER_PATH}/English.lproj/BibDesk\ Help

html:
	${texi2html} ${INPUT} --prefix=bibdesk-manual --split=chapter

applehelp:
	${texi2html} ${INPUT} --init-file=applehelp.init --prefix="BibDesk Help" --output=${DEST} --split=node ;\
	cp -r gfx ${DEST}/;
	perl -pi -e 's#<!--AppleMeta-->#<meta name=\"AppleTitle\" content=\"BibDesk Help\"><meta name=\"AppleIcon\" content=\"BibDesk%20Help/gfx/bibDeskIcon.png\"><meta name=\"robots\" content=\"anchors\">#' ${DEST}/BibDesk\ Help.html
#section#chapter

pdf:
	echo "PDF target does nothing right now."