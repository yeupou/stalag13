SHELL = /bin/bash
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
	@echo "  create directories"
	for content in  `find etc/* usr/* -type d -print`; do \
		mkdir -p $(PREFIX)$$content ; \
	done
	@echo "  install files"	
	for content in  `find etc/* usr/* ! -type d -print`; do \
		install $$content $(PREFIX)$$content ; \
	done
	@echo "  adding useful symlinks"	
	for content in $(PREFIX)usr/local/bin/* ; do \
		cd $(PREFIX)usr/local/bin/ && if [ `basename $$content | grep -vc stalag13` == 1 ]; then ln -fs /usr/local/bin/`basename $$content` $(PREFIX)usr/local/bin/`basename $$content | sed s/\\.[^.]*$$//g`; fi ; \
	done
	for content in $(PREFIX)usr/local/bin/stalag13-* ; do \
		cd $(PREFIX)usr/local/bin/ && ln -fs /usr/local/bin/`basename $$content` $(PREFIX)usr/local/bin/`basename $$content | sed s/^stalag13-//g | sed s/\\.[^.]*$$//g`; \
	done

log:
	git log --stat -n100 --pretty=format:"%s of %ad" > ChangeLog


deb-prerelease:
	@echo "New prerelease "$(NEWPREVERSION)" (on top of "$(MAJORVERSION).$(VERSION)")"
	debian/makechangelog.sh $(MAJORVERSION) $(VERSION) $(NEWPREVERSION)
	cd debian && rm -f changelog && ln -s changelog.full changelog
	echo $(VERSION) > $(LATESTIS)
	echo $(NEWPREVERSION) >> $(LATESTIS)
	@git commit -a -m 'New prerelease $(NEWPREVERSION) (on top of $(MAJORVERSION).$(VERSION))'
	make log
	dpkg-buildpackage -uc -us -rfakeroot
	su -c "dpkg -i ../stalag13-utils_$(MAJORVERSION).$(VERSION)+$(NEWPREVERSION)*.deb"

deb-release:
	@echo "New release "$(MAJORVERSION).$(NEWVERSION)
	debian/makechangelog.sh $(MAJORVERSION) $(NEWVERSION)
	cd debian && rm -f changelog && ln -s changelog.releases changelog
	echo $(NEWVERSION) > $(LATESTIS)
	echo 0 >> $(LATESTIS)
	@git commit -a -m "`cat debian/changelog  | head -3 | tail -1 | sed s/^\ \ \\\*\ //;` (new release $(MAJORVERSION).$(NEWVERSION))"
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

