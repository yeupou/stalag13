PREFIX = /
LATESTIS = LATESTIS
VERSION = $(shell cat $(LATESTIS))
NEWVERSION = $(shell expr $(VERSION) \+ 1)
WHOAMI = $(shell whoami)

install: clean
	for content in etc/* usr/* var/* ; do \
		if [ -d $$content ] && [ `basename $$content` != "CVS" ]; then \
			for subcontent in $$content/* ; do \
				if [ -d $$subcontent ] && [ `basename $$subcontent` != "CVS" ]; then \
					for subsubcontent in $$subcontent/* ; do \
						if [ -d $$subsubcontent ] && [ `basename $$subsubcontent` != "CVS" ]; then \
							for subsubsubcontent in $$subsubcontent/* ; do \
								install $$subsubsubcontent $(PREFIX)$$subsubsubcontent ; \
							done \
						elif  [ `basename $$subsubcontent` != "CVS" ]; then \
							install $$subsubcontent $(PREFIX)$$subsubcontent ; \
						fi \
					done \
				elif [ `basename $$subcontent` != "CVS" ]; then \
					install $$subcontent $(PREFIX)$$subcontent; \
				fi \
			done \
		elif [ `basename $$content` != "CVS" ]; then \
			install $$content $(PREFIX)$$content; \
		fi \
	done
	mkdir -p $(PREFIX)usr/bin $(PREFIX)usr/local/bin
#	ln -s /usr/bin/juk $(PREFIX)usr/local/bin/xmms
#	rm -rf /usr/src/cgn
#	cp -rf . /usr/src/cgn


deb:
	make clean-prev-dir
#	@echo "A lancer en root"
#	if [ $(WHOAMI) != "root" ]; then exit ; fi
	@echo "nouvelle version : "$(NEWVERSION)
#CGN	@cvs2cl
	debian/makechangelog.sh $(NEWVERSION)
	echo $(NEWVERSION) > $(LATESTIS)
#CGN	@cvs ci -m 'nouvelle version $(NEWVERSION)'
	dpkg-buildpackage -uc -us -rfakeroot
	su -c "dpkg -i ../stalag13-utils_2.$(NEWVERSION)*.deb"
	make clean
	make chmod

move:
#CGN	scp ../cgn_*.deb gate:/stock/debian/stable-all
#CGN	scp ../cgn-depends_*.deb gate:/stock/debian/stable-all

clean:
	mrclean .
	rm -f backup*
	rm -rf doc-pak

clean-prev-dir:
	rm -f ../cgn_* ../cgn-depends_* 

clean-deb-dir:
#CGN	ssh gate "rm -f /stock/debian/stable-all/cgn_* /stock/debian/stable-all/cgn-depends_*"

chmod:
#	chmod a+w . -Rv

everything: deb move clean-prev-dir