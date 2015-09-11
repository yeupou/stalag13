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
SSH = 22
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
	-su -c "dpkg -i ../stalag13-utils-ahem_$(MAJORVERSION).$(VERSION)+$(NEWPREVERSION)*.deb ../stalag13-utils_$(MAJORVERSION).$(VERSION)+$(NEWPREVERSION)*.deb"

deb-release:
	@echo "New release "$(MAJORVERSION).$(NEWVERSION)
	debian/makechangelog.sh $(MAJORVERSION) $(NEWVERSION)
	cd debian && rm -f changelog && ln -s changelog.releases changelog
	# update the LATESTIS reminder file as if it were a pre release
	# so it increases the commit count
	echo $(VERSION) > $(LATESTIS)
	echo $(NEWPREVERSION) >> $(LATESTIS)
	# build the package early to make sure everything is okay
	dpkg-buildpackage -uc -us -rfakeroot
	# update at the last minute the LATESTIS reminder file, when no one
	# needs exactly the commit count
	echo $(NEWVERSION) > $(LATESTIS)
	echo 0 >> $(LATESTIS)
	# then commit changes, assuming it worked ok 
	@git commit -a -m "`cat debian/changelog  | head -3 | tail -1 | sed s/^\ \ \\\*\ //;` (new release $(MAJORVERSION).$(NEWVERSION))"
	@git push
	@git push github
	-su -c "dpkg -i ../stalag13-utils-ahem_$(MAJORVERSION).$(NEWVERSION)*.deb ../stalag13-utils_$(MAJORVERSION).$(NEWVERSION)*.deb"

pre: prerelease

prerelease: clean-prev-dir readme deb-prerelease clean move-prepare move-local

rel: release

release: clean-prev-dir readme deb-release clean move-prepare move

norel: move-grab move-sign move

keys:
	$(eval KEYS = 1)
	@echo Will update the keyring package

pxe:
	@echo Will update the pxe package
	touch debian/utils-pxe.rebuild

sshn:
	$(eval SSH = 22222)

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

move-grab:
	$(eval TEMPDIR := $(shell mktemp --directory)) 
	cd $(TEMPDIR) && scp porche.rien.pl:/srv/www/apt/* .
	# remove apt files
	cd $(TEMPDIR) && rm -f Packages* Release* InRelease*

move-litter:
	# only keep the latest build
	cd $(TEMPDIR) && rm -f stalag13-utils_*.deb 
	cd ../ && for deb in stalag13-utils*.deb; do \
		if [ `echo $$deb | cut -f 1 -d "_"` != "stalag13-utils" ]; then \
			rm -f $(TEMPDIR)/`echo $$deb | cut -f 1 -d "_"`*; \
		fi ; \
		cp $$deb $(TEMPDIR); \
	done
	# update the keyring only if make was called with 'keys' 
	if [ $(KEYS) != 0 ]; then cd $(TEMPDIR) && rm -f stalag13-keyring*.deb; fi
	if [ $(KEYS) != 0 ]; then cp ../stalag13-keyring_$(MAJORVERSION).*.deb $(TEMPDIR)/; fi
	if [ $(KEYS) != 0 ]; then cd $(TEMPDIR) && ln -s stalag13-keyring_$(MAJORVERSION).*.deb stalag13-keyring.deb; fi

move-sign:
	# build proper required repository files
	cd $(TEMPDIR) && apt-ftparchive packages . > Packages 
	cd $(TEMPDIR) && apt-ftparchive release . > Release && gpg --clearsign -o InRelease Release && gpg -abs -o Release.gpg Release

move-prepare: move-grab move-litter move-sign

move-local:
	cd $(TEMPDIR) && rsync -rl --chmod=ug=rw -chmod=o=rWX --delete -e "ssh -p $(SSH)"  . root@porche.rien.pl:/srv/www/apt/
	rm -r $(TEMPDIR)

move:
	cd $(TEMPDIR) && rsync -rl --chmod=ug=rw -chmod=o=rWX --delete -e "ssh -p $(SSH)" . root@porche.rien.pl:/var/www/apt/
	cd $(TEMPDIR) && rsync -rl --chmod=ug=rw -chmod=o=rWX --delete . root@survie.rien.pl:/var/www/apt/
	rm -r $(TEMPDIR)
