SHELL = /bin/bash
PREFIX = /
LATESTIS = LATESTIS
MAJORVERSION = 3
VERSION = $(shell cat $(LATESTIS) | head -1)
PREVERSION = $(shell cat $(LATESTIS) | tail -1)
NEWVERSION = $(shell expr $(VERSION) \+ 1)
NEWPREVERSION = $(shell expr $(PREVERSION) \+ 1)
WHOAMI = $(shell whoami)
KEYS = 0
$(eval TEMPDIR := $(shell mktemp --directory)) 

install: clean
	@echo "INSTALL WITH PREFIX "$(PREFIX)
	# create directories. 755 mode per debian policy
	for content in  `find etc/* usr/* var/* -type d -print`; do \
		mkdir --mode=755 -p $(PREFIX)$$content ; \
	done
	# install files. 755 mode per debian policy for executable
	#                644 otherwise
	# for symlinks, use cp as install would not keep it as a link
	for content in  `find etc/* usr/* var/* ! -type d -print`; do \
		if [ ! -L $$content ]; then \
			if [ -x $$content ]; then mode=755; else mode=644; fi ; \
			install --mode=$$mode $$content $(PREFIX)$$content ; \
		else \
			cp -a $$content $(PREFIX)$$content ; \
		fi ; \
	done
	# create extra useful symlinks
	for content in $(PREFIX)usr/local/bin/* ; do \
		cd $(PREFIX)usr/local/bin/ && if [ `basename $$content | grep -vc stalag13` == 1 ]; then ln -fs /usr/local/bin/`basename $$content` $(PREFIX)usr/local/bin/`basename $$content | sed s/\\.[^.]*$$//g`; fi ; \
	done
	for content in $(PREFIX)usr/local/bin/stalag13-* ; do \
		cd $(PREFIX)usr/local/bin/ && ln -fs /usr/local/bin/`basename $$content` $(PREFIX)usr/local/bin/`basename $$content | sed s/^stalag13-//g | sed s/\\.[^.]*$$//g`; \
	done

log:
	git log --stat -n100 --pretty=format:"%s of %ad" > ChangeLog

readme:
	debian/makereadme.pl

deb-prerelease:
	@echo "New prerelease "$(NEWPREVERSION)" (on top of "$(MAJORVERSION).$(VERSION)")"
	debian/makechangelog.sh $(MAJORVERSION) $(VERSION) $(NEWPREVERSION)

	cd debian && rm -f changelog && ln -s changelog.full changelog
	echo $(VERSION) > $(LATESTIS)
	echo $(NEWPREVERSION) >> $(LATESTIS)
	@git commit -a -m 'New prerelease $(NEWPREVERSION) (on top of $(MAJORVERSION).$(VERSION))'
	git push
	make log
	dpkg-buildpackage -uc -us -rfakeroot
	su -c "dpkg -i ../stalag13-utils-ahem_$(MAJORVERSION).$(VERSION)+$(NEWPREVERSION)*.deb ../stalag13-utils_$(MAJORVERSION).$(VERSION)+$(NEWPREVERSION)*.deb"

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
	su -c "dpkg -i ../stalag13-utils-ahem_$(MAJORVERSION).$(NEWVERSION)*.deb ../stalag13-utils_$(MAJORVERSION).$(NEWVERSION)*.deb"

pre: prerelease

prerelease: clean-prev-dir readme deb-prerelease clean move-local

rel: release

release: clean-prev-dir readme deb-release clean move

keys:
	$(eval KEYS = 1)
	@echo Will update the keyring package

clean:
	find . \( -name "#*#" -or -name ".#*" -or -name "*~" -or -name ".*~" \) -exec rm -rfv {} \;
	rm -f backup*
	rm -rf doc-pak
	# remove not updated packages
	if [ -e debian/notupdated ]; then \
		while read package; do \
			rm -vf ../stalag13-$$package*.deb; \
		done < debian/notupdated; \
	fi

clean-prev-dir:
	rm -f ../stalag13-utils*.deb ../stalag13-utils*.changes ../stalag13-keyring_* ../stalag13-utils*.tar.gz ../stalag13-utils*.dsc

move-prepare:
	# can be done only within stalag13 network
	$(eval TEMPDIR := $(shell mktemp --directory)) 
	cd $(TEMPDIR) && scp gate:/srv/www/apt/* .
	# only keep the latest build
	cd $(TEMPDIR) && rm -f stalag13-utils_*.deb stalag13-utils-ahem*.deb Packages* Release* InRelease*
	cd ../ && for deb in stalag13-utils*.deb; do \
		echo rm -fv $(TEMPDIR)/`echo $$deb | cut -f 1 -d "_"`*; \
		echo cp $$deb $(TEMPDIR); \
	done
#	cp ../stalag13-utils*_$(MAJORVERSION).*.deb $(TEMPDIR)/
	# update the keyring only if make was called with 'keys' 
	if [ $(KEYS) != 0 ]; then cd $(TEMPDIR) && rm -f stalag13-keyring_*.deb; fi
	if [ $(KEYS) != 0 ]; then cp ../stalag13-keyring_$(MAJORVERSION).*.deb $(TEMPDIR)/; fi
	if [ $(KEYS) != 0 ]; then cd $(TEMPDIR) && ln -s stalag13-keyring_$(MAJORVERSION).*.deb stalag13-keyring.deb; fi
	# build proper required repository files
	cd $(TEMPDIR) && apt-ftparchive packages . > Packages 
	cd $(TEMPDIR) && apt-ftparchive release . > Release && gpg --clearsign -o InRelease Release && gpg -abs -o Release.gpg Release

move-local: move-prepare
	cd $(TEMPDIR) && rsync -rl --chmod=ug=rw -chmod=o=rWX --delete . root@gate:/srv/www/apt/
	rm -r $(TEMPDIR)

move: move-prepare
	cd $(TEMPDIR) && rsync -rl --chmod=ug=rw -chmod=o=rWX --delete . root@gate:/var/www/apt/
	cd $(TEMPDIR) && rsync -rl --chmod=ug=rw -chmod=o=rWX --delete . root@survival:/var/www/apt/
	rm -r $(TEMPDIR)
