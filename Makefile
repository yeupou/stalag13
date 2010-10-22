PREFIX = /
LATESTIS = LATESTIS
VERSION = $(shell cat $(LATESTIS))
NEWVERSION = $(shell expr $(VERSION) \+ 1)
WHOAMI = $(shell whoami)

install: clean
	@echo "INSTALL WITH PREFIX "$(PREFIX)
	for content in etc/* usr/* var/* ; do \
		if [ -d $$content ]; then \
			for subcontent in $$content/* ; do \
				if [ -d $$subcontent ]; then \
					for subsubcontent in $$subcontent/* ; do \
						if [ -d $$subsubcontent ]; then \
							for subsubsubcontent in $$subsubcontent/* ; do \
								install $$subsubsubcontent $(PREFIX)$$subsubsubcontent ; \
							done \
						elif [ -e $$subsubcontent ]; then \
							install $$subsubcontent $(PREFIX)$$subsubcontent ; \
						fi \
					done \
				elif [ -e $$subcontent ]; then \
					install $$subcontent $(PREFIX)$$subcontent; \
				fi \
			done \
		elif [ -e $$content ]; then \
			install $$content $(PREFIX)$$content; \
		fi \
	done
	mkdir -p $(PREFIX)usr/bin $(PREFIX)usr/local/bin
	for content in $(PREFIX)usr/local/bin/stalag13-* ; do \
		cd $(PREFIX)usr/local/bin/ && ln -fs /usr/local/bin/`basename $$content` $(PREFIX)usr/local/bin/`basename $$content | sed s/^stalag13-//g | sed s/\\.[^.]*$$//g`; \
	done
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
	@git commit -a -m 'nouvelle version $(NEWVERSION)'
	@git push
	dpkg-buildpackage -uc -us -rfakeroot
	su -c "dpkg -i ../stalag13-utils_2.$(NEWVERSION)*.deb"
	make clean
	make chmod

move:
#CGN	scp ../cgn_*.deb gate:/stock/debian/stable-all
#CGN	scp ../cgn-depends_*.deb gate:/stock/debian/stable-all
	ssh moe "rm -f stalag13-utils_2.*.deb"
	scp ../stalag13-utils_2.*.deb moe:~/
	ssh root@moe "cd /var/www/apt && rm -f stalag13-utils_2.*.deb && cp /home/klink/stalag13-utils_2.*.deb . && apt-ftparchive packages . > Packages && gzip -f Packages && dpkg -i stalag13-utils_2.*.deb"

clean:
	mrclean .
	rm -f backup*
	rm -rf doc-pak

clean-prev-dir:
	rm -f ../cgn_* ../cgn-depends_* 
	rm -f ../stalag13-utils_* ../stalag13-utils-depends_* 

clean-deb-dir:
#CGN	ssh gate "rm -f /stock/debian/stable-all/cgn_* /stock/debian/stable-all/cgn-depends_*"

chmod:
#	chmod a+w . -Rv

everything: deb move clean-prev-dir