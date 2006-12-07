texi2html = ./texi2html
#makeinfo

INPUT = BibDesk\ Help/bibdesk.texi

all: applehelp html pdf

# use the longer one for xcode.
# NOTE:: must be done after the copy resources build phase.
#DEST = .
#DEST = ${BUILD_DIR}/${UNLOCALIZED_RESOURCES_FOLDER_PATH}/English.lproj/BibDesk\ Help
DEST = BibDesk\ Help
LOC_DIR = ${SOURCE_ROOT}/English.lproj

html:
	${texi2html} ${LOC_DIR}/${INPUT} --prefix=bibdesk-manual --split=chapter

applehelp:
	for LOC_DIR in ${SOURCE_ROOT}/*.lproj; do \
	${texi2html} ${LOC_DIR}/${INPUT} --init-file=applehelp.init --prefix="BibDesk Help" --output=${LOC_DIR}/${DEST} --split=node ;\
	perl -pi -e 's#<!--AppleMeta-->#<meta name=\"AppleTitle\" content=\"BibDesk Help\"><meta name=\"AppleIcon\" content=\"BibDesk%20Help/gfx/bibDeskIcon.png\"><meta name=\"robots\" content=\"anchors\">#' ${LOC_DIR}/${DEST}/BibDesk\ Help.html;\
	python postprocess-nontitle.py ${LOC_DIR}/${DEST}/BibDesk\ Help_*.html;\
	done;
#section#chapter

pdf:
	echo "PDF target does nothing right now."