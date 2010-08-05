#!/usr/bin/make
#
# Makefile for SchoolTool trunk buildbot
#

DIST=/home/ftp/pub/schooltool/trunk
BOOTSTRAP_PYTHON=python

INSTANCE_TYPE=schooltool
BUILDOUT_FLAGS=

SCHOOLTOOL_BZR=http://source.schooltool.org/var/local/bzr/schooltool
LP=http://bazaar.launchpad.net/~schooltool-owners
PACKAGES=src/schooltool src/schooltool.gradebook src/schooltool.intervention src/schooltool.lyceum.journal src/schooltool.cas src/schooltool.stapp2008fall

.PHONY: all
all: build

.PHONY: build
build: $(PACKAGES) bin/test

.PHONY: bootstrap
bootstrap bin/buildout python:
	$(BOOTSTRAP_PYTHON) bootstrap.py

.PHONY: buildout
buildout bin/test: python bin/buildout buildout.cfg schooltool.cfg versions.cfg
	bin/buildout $(BUILDOUT_FLAGS)
	@touch --no-create bin/test

src/.bzr:
	# if default format is 2a, cannot push branches back to Launchpad
	bzr init-repo --pack-0.92 src

src/schooltool: src/.bzr
	bzr co $(LP)/schooltool/trunk/ src/schooltool

src/schooltool.gradebook: src/.bzr
	bzr co $(LP)/schooltool.gradebook/trunk/ src/schooltool.gradebook

src/schooltool.intervention: src/.bzr
	bzr co $(LP)/schooltool.intervention/trunk/ src/schooltool.intervention

src/schooltool.lyceum.journal: src/.bzr
	bzr co $(LP)/schooltool.lyceum.journal/trunk/ src/schooltool.lyceum.journal

src/schooltool.stapp2008fall: src/.bzr
	bzr co $(SCHOOLTOOL_BZR)/schooltool.stapp2008fall/trunk/ src/schooltool.stapp2008fall

src/schooltool.cas: src/.bzr
	bzr co $(LP)/schooltool.cas/trunk/ src/schooltool.cas

.PHONY: bzrupdate
bzrupdate: $(PACKAGES)
	@for package in $(PACKAGES) ; do \
	    echo Updating $${package} ; \
	    bzr up $${package} ; \
	done

.PHONY: update
update: bzrupdate
	$(MAKE) buildout BUILDOUT_FLAGS=-n

instance:
	$(MAKE) buildout
	bin/make-schooltool-instance instance instance_type=$(INSTANCE_TYPE)

.PHONY: run
run: build instance
	bin/start-schooltool-instance instance

.PHONY: tags
tags: build
	bin/tags

.PHONY: clean
clean:
	rm -rf bin develop-eggs parts python
	rm -f .installed.cfg
	rm -f ID TAGS tags
	find . -name '*.py[co]' -exec rm -f {} \;

# Tests

.PHONY: test
test: build
	bin/test --at-level 2 -u

.PHONY: ftest
ftest: build
	bin/test --at-level 2 -f

# Coverage

.PHONY: coverage
coverage: build
	test -d parts/test/coverage && ! test -d coverage && mv parts/test/coverage . || true
	rm -rf coverage
	bin/test --at-level 2 -u --coverage=coverage
	mv parts/test/coverage .

.PHONY: coverage-reports-html
coverage-reports-html coverage/reports: build
	test -d parts/test/coverage && ! test -d coverage && mv parts/test/coverage . || true
	rm -rf coverage/reports
	mkdir coverage/reports
	bin/coverage coverage coverage/reports
	ln -s schooltool.html coverage/reports/index.html

.PHONY: publish-coverage-reports
publish-coverage-reports: coverage/reports
	@test -n "$(DESTDIR)" || { echo "Please specify DESTDIR"; exit 1; }
	cp -r coverage/reports $(DESTDIR).new
	chmod -R a+rX $(DESTDIR).new
	rm -rf $(DESTDIR).old
	mv $(DESTDIR) $(DESTDIR).old || true
	mv $(DESTDIR).new $(DESTDIR)

.PHONY: ftest-coverage
ftest-coverage: build
	test -d parts/test/ftest-coverage && ! test -d ftest-coverage && mv parts/test/ftest-coverage . || true
	rm -rf ftest-coverage
	bin/test --at-level 2 -f --coverage=ftest-coverage
	mv parts/test/ftest-coverage .

.PHONY: ftest-coverage-reports-html
ftest-coverage-reports-html ftest-coverage/reports: build
	test -d parts/test/ftest-coverage && ! test -d ftest-coverage && mv parts/test/ftest-coverage . || true
	rm -rf ftest-coverage/reports
	mkdir ftest-coverage/reports
	bin/coverage ftest-coverage ftest-coverage/reports
	ln -s schooltool.html ftest-coverage/reports/index.html

.PHONY: publish-ftest-coverage-reports
publish-ftest-coverage-reports: ftest-coverage/reports
	@test -n "$(DESTDIR)" || { echo "Please specify DESTDIR"; exit 1; }
	cp -r ftest-coverage/reports $(DESTDIR).new
	chmod -R a+rX $(DESTDIR).new
	rm -rf $(DESTDIR).old
	mv $(DESTDIR) $(DESTDIR).old || true
	mv $(DESTDIR).new $(DESTDIR)

# Translations

.PHONY: extract-translations
extract-translations: build
	bin/i18nextract --egg schooltool \
	                --domain schooltool \
	                --zcml schooltool/common/translations.zcml \
	                --output-file src/schooltool/src/schooltool/locales/schooltool.pot
	bin/i18nextract --egg schooltool \
	                --domain schooltool.commendation \
	                --zcml schooltool/commendation/translations.zcml \
	                --output-file src/schooltool/src/schooltool/commendation/locales/schooltool.commendation.pot
	bin/i18nextract --egg schooltool.gradebook \
	                --domain schooltool.gradebook \
	                --zcml schooltool/gradebook/translations.zcml \
	                --output-file src/schooltool.gradebook/src/schooltool/gradebook/locales/schooltool.gradebook.pot
	bin/i18nextract --egg schooltool.intervention \
	                --domain schooltool.intervention \
	                --zcml schooltool/intervention/translations.zcml \
	                --output-file src/schooltool.intervention/src/schooltool/intervention/locales/schooltool.intervention.pot
	bin/i18nextract --egg schooltool.lyceum.journal \
	                --domain schooltool.lyceum.journal \
	                --zcml schooltool/lyceum/journal/translations.zcml \
	                --output-file src/schooltool.lyceum.journal/src/schooltool/lyceum/journal/locales/schooltool.lyceum.journal.pot

.PHONY: compile-translations
compile-translations:
	set -e; \
	locales=src/schooltool/src/schooltool/locales; \
	for f in $${locales}/*.po; do \
	    mkdir -p $${f%.po}/LC_MESSAGES; \
	    msgfmt -o $${f%.po}/LC_MESSAGES/schooltool.mo $$f;\
	done
	locales=src/schooltool/src/schooltool/commendation/locales; \
	for f in $${locales}/*.po; do \
	    mkdir -p $${f%.po}/LC_MESSAGES; \
	    msgfmt -o $${f%.po}/LC_MESSAGES/schooltool.commendation.mo $$f;\
	done
	locales=src/schooltool.gradebook/src/schooltool/gradebook/locales; \
	for f in $${locales}/*.po; do \
	    mkdir -p $${f%.po}/LC_MESSAGES; \
	    msgfmt -o $${f%.po}/LC_MESSAGES/schooltool.gradebook.mo $$f;\
	done
	locales=src/schooltool.intervention/src/schooltool/intervention/locales; \
	for f in $${locales}/*.po; do \
	    mkdir -p $${f%.po}/LC_MESSAGES; \
	    msgfmt -o $${f%.po}/LC_MESSAGES/schooltool.intervention.mo $$f;\
	done
	locales=src/schooltool.lyceum.journal/src/schooltool/lyceum/journal/locales; \
	for f in $${locales}/*.po; do \
	    mkdir -p $${f%.po}/LC_MESSAGES; \
	    msgfmt -o $${f%.po}/LC_MESSAGES/schooltool.lyceum.journal.mo $$f;\
	done

.PHONY: update-translations
update-translations: extract-translations
	set -e; \
	locales=src/schooltool/src/schooltool/locales; \
	for f in $${locales}/*.po; do \
	    msgmerge -qUF $$f $${locales}/schooltool.pot ;\
	done
	locales=src/schooltool/src/schooltool/commendation/locales; \
	for f in $${locales}/*.po; do \
	    msgmerge -qUF $$f $${locales}/schooltool.commendation.pot ;\
	done
	locales=src/schooltool.gradebook/src/schooltool/gradebook/locales; \
	for f in $${locales}/*.po; do \
	    msgmerge -qUF $$f $${locales}/schooltool.gradebook.pot ;\
	done
	locales=src/schooltool.intervention/src/schooltool/intervention/locales; \
	for f in $${locales}/*.po; do \
	    msgmerge -qUF $$f $${locales}/schooltool.intervention.pot ;\
	done
	locales=src/schooltool.lyceum.journal/src/schooltool/lyceum/journal/locales; \
	for f in $${locales}/*.po; do \
	    msgmerge -qUF $$f $${locales}/schooltool.lyceum.journal.pot ;\
	done
	$(MAKE) compile-translations

# Release

.PHONY: release
release: bin/buildout compile-translations
	set -e
	echo "[versions]" > trunk.cfg
	@for package in $(PACKAGES) ; do \
	    version=`cat $${package}/version.txt.in`-r`bzr revno $${package}` ; \
	    echo -n $${version} > $${package}/version.txt ; \
	    bin/buildout setup $${package}/setup.py sdist ; \
	    echo "`echo $${package} | sed s,build\\/,,` = $${version}" >> trunk.cfg ; \
	done

.PHONY: move-release
move-release:
	test -w $(DIST)
	mkdir -p $(DIST)/dev
	mv -fv trunk.cfg $(DIST)/dev
	@for package in $(PACKAGES) ; do \
	    mv -v $${package}/dist/*.tar.gz $(DIST)/dev ; \
	done
	cp -uv versions.cfg $(DIST)

# Helpers

.PHONY: ubuntu-environment
ubuntu-environment:
	sudo apt-get install bzr build-essential python-all-dev libc6-dev libicu-dev libxslt1-dev libfreetype6-dev libjpeg62-dev
