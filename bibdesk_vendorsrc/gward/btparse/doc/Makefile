# Makefile for the 'doc' directory of the btparse distribution

include ../Makefile.defs        # for installation dirs
include ../Makefile.version	# get VERSION and RELEASE_DATE macros

POD = btparse.pod \
      bt_language.pod \
      bt_input.pod \
      bt_traversal.pod \
      bt_postprocess.pod \
      bt_macros.pod \
      bt_split_names.pod \
      bt_format_names.pod \
      bt_misc.pod

MAN3 = $(POD:.pod=.3)

.SUFFIXES : .pod .3

.pod.3:
	pod2man --section=3 \
                --release="btparse, version $(VERSION)" \
                --center="btparse" \
                --date="$(RELEASE_DATE)" \
                $< > $@

man : $(MAN3)

clean :
	rm -f $(MAN3)

install : man
	$(INSTALL) -d $(INSTALL_MAN3)
	cp $(MAN3) $(INSTALL_MAN3)
	cd $(INSTALL_MAN3) && chmod 0644 $(MAN3)
