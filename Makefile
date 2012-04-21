PREFIX = /
LATESTIS = LATESTIS
MAJORVERSION = 3
VERSION = $(shell cat $(LATESTIS) | head -1)
PREVERSION = $(shell cat $(LATESTIS) | tail -1)
NEWVERSION = $(shell expr $(VERSION) \+ 1)
NEWPREVERSION = $(shell expr $(PREVERSION) \+ 1)
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
								mkdir -p $(PREFIX)`dirname $$subsubsubcontent` ; \
								install $$subsubsubcontent $(PREFIX)$$subsubsubcontent ; \
							done \
						elif [ -e $$subsubcontent ]; then \
							mkdir -p $(PREFIX)`dirname $$subsubcontent` ; \
							install $$subsubcontent $(PREFIX)$$subsubcontent ; \
						fi \
					done \
				elif [ -e $$subcontent ]; then \
					mkdir -p $(PREFIX)`dirname $$subcontent` ; \
					install $$subcontent $(PREFIX)$$subcontent; \
				fi \
			done \
		elif [ -e $$content ]; then \
			mkdir -p $(PREFIX)`dirname $$content` ; \
			install $$content $(PREFIX)$$content; \
		fi \
	done
	for content in $(PREFIX)usr/local/bin/* ; do \
		cd $(PREFIX)usr/local/bin/ && echo "############### :`$$content | grep -vc ^stalag13-` && if [ `echo $$content | grep -vc ^stalag13-` ]; then ln -fs /usr/local/bin/`basename $$content` $(PREFIX)usr/local/bin/`basename $$content | sed s/\\.[^.]*$$//g`; fi ; \
	done
	for content in $(PREFIX)usr/local/bin/stalag13-* ; do \
		cd $(PREFIX)usr/local/bin/ && ln -fs /usr/local/bin/`basename $$content` $(PREFIX)usr/local/bin/`basename $$content | sed s/^stalag13-//g | sed s/\\.[^.]*$$//g`; \
	done

log:
	git log --stat -n50 --pretty=format:"%s of %ar" > ChangeLog

deb-prerelease:
	@echo "New prerelease "$(NEWPREVERSION)" (on top of "$(MAJORVERSION).$(VERSION)")"
	debian/makechangelog.sh $(MAJORVERSION) $(VERSION) $(NEWPREVERSION)
	echo $(VERSION) > $(LATESTIS)
	echo $(NEWPREVERSION) >> $(LATESTIS)
	@git commit -a -m 'New prerelease $(NEWPREVERSION) (on top of $(MAJORVERSION).$(VERSION))'
	make log
	dpkg-buildpackage -uc -us -rfakeroot
	su -c "dpkg -i ../stalag13-utils_$(MAJORVERSION).$(VERSION)+$(NEWPREVERSION)*.deb"

deb-release:
	@echo "New release "$(MAJORVERSION).$(NEWVERSION)
	debian/makechangelog.sh $(MAJORVERSION) $(NEWVERSION)
	echo $(NEWVERSION) > $(LATESTIS)
	echo 0 >> $(LATESTIS)
	@git commit -a -m 'New release $(MAJORVERSION).$(NEWVERSION)'
	@git push
	@git push github
	make log
	dpkg-buildpackage -uc -us -rfakeroot
	su -c "dpkg -i ../stalag13-utils_$(MAJORVERSION).$(NEWVERSION)*.deb"

pre: prerelease

prerelease: clean-prev-dir deb-prerelease clean move

rel: release

release: clean-prev-dir deb-release clean move

clean:
	find . \( -name "#*#" -or -name ".#*" -or -name "*~" -or -name ".*~" \) -exec rm -rfv {} \;
	rm -f backup*
	rm -rf doc-pak

clean-prev-dir:
	rm -f ../cgn_* ../cgn-depends_* 
	rm -f ../stalag13-utils_* ../stalag13-utils-depends_* ../stalag13-utils-extra_*

move:
	ssh gate "rm -f stalag13-utils_$(MAJORVERSION).*.deb stalag13-utils-extra_$(MAJORVERSION).*.deb"
	scp ../stalag13-utils*_$(MAJORVERSION).*.deb moe:~/
	ssh root@gate "cd /var/www/apt && rm -f stalag13-utils_$(MAJORVERSION).*.deb stalag13-utils-extra_$(MAJORVERSION).*.deb && cp /home/klink/stalag13-utils*_$(MAJORVERSION).*.deb . && apt-ftparchive packages . > Packages && gzip -f Packages && dpkg -i stalag13-utils_$(MAJORVERSION).*.deb"

