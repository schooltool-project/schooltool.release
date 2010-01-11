#!/usr/bin/make
#
# Makefile for SchoolTool trunk buildbot
#

BOOTSTRAP_PYTHON=python2.5
SCHOOLTOOL_BZR='http://source.schooltool.org/var/local/bzr/schooltool'
LP='http://bazaar.launchpad.net/~schooltool-owners'
DIST='/home/ftp/pub/schooltool/1.4'
PACKAGES=build/schooltool build/schooltool.gradebook build/schooltool.intervention build/schooltool.lyceum.journal build/schooltool.cas build/schooltool.stapp2008fall

.PHONY: all
all: build

# Sandbox

.PHONY: build
build: bin/test-all $(PACKAGES)

.PHONY: bootstrap
bootstrap bin/buildout:
	$(BOOTSTRAP_PYTHON) bootstrap.py

.PHONY: buildout
buildout bin/test-all: bin/buildout buildout.cfg versions.cfg
	-bin/buildout $(BUILDOUT_FLAGS)
	@touch --no-create bin/test-all

build/.bzr:
	bzr init-repo build

build/schooltool: build/.bzr
	bzr co $(LP)/schooltool/trunk/ build/schooltool

build/schooltool.gradebook: build/.bzr
	bzr co $(LP)/schooltool.gradebook/trunk/ build/schooltool.gradebook

build/schooltool.intervention: build/.bzr
	bzr co $(LP)/schooltool.intervention/trunk/ build/schooltool.intervention

build/schooltool.lyceum.journal: build/.bzr
	bzr co $(LP)/schooltool.lyceum.journal/trunk/ build/schooltool.lyceum.journal

build/schooltool.stapp2008fall: build/.bzr
	bzr co $(SCHOOLTOOL_BZR)/schooltool.stapp2008fall/trunk/ build/schooltool.stapp2008fall

build/schooltool.cas: build/.bzr
	bzr co $(LP)/schooltool.cas/trunk/ build/schooltool.cas

.PHONY: bzrupdate
bzrupdate: $(PACKAGES)
	@for package in $(PACKAGES) ; do \
	    bzr up $${package} ; \
	done

.PHONY: update
update: bzrupdate bin/buildout
	$(MAKE) buildout BUILDOUT_FLAGS=-n

# Tests

.PHONY: test
test: build
	bin/test-all --at-level 2 -u

.PHONY: ftest
ftest: build
	bin/test-all --at-level 2 -f

# Coverage

.PHONY: coverage
coverage: build
	test -d parts/test-all/coverage && ! test -d coverage && mv parts/test-all/coverage . || true
	rm -rf coverage
	bin/test-all --at-level 2 -u --coverage=coverage
	mv parts/test-all/coverage .

.PHONY: coverage-reports-html
coverage-reports-html coverage/reports: build
	test -d parts/test-all/coverage && ! test -d coverage && mv parts/test-all/coverage . || true
	rm -rf coverage/reports
	mkdir coverage/reports
	bin/coverage coverage coverage/reports
	ln -s schooltool.html coverage/reports/index.html

.PHONY: ftest-coverage
ftest-coverage: build
	test -d parts/test-all/ftest-coverage && ! test -d ftest-coverage && mv parts/test-all/ftest-coverage . || true
	rm -rf ftest-coverage
	bin/test-all --at-level 2 -f --coverage=ftest-coverage
	mv parts/test-all/ftest-coverage .

.PHONY: ftest-coverage-reports-html
ftest-coverage-reports-html ftest-coverage/reports: build
	test -d parts/test-all/ftest-coverage && ! test -d ftest-coverage && mv parts/test-all/ftest-coverage . || true
	rm -rf ftest-coverage/reports
	mkdir ftest-coverage/reports
	bin/coverage ftest-coverage ftest-coverage/reports
	ln -s schooltool.html ftest-coverage/reports/index.html

# Translations

.PHONY: extract-translations
extract-translations: build
	bin/i18nextract --egg schooltool \
	                --domain schooltool \
	                --zcml schooltool/common/translations.zcml \
                        --output-file build/schooltool/src/schooltool/locales/schooltool.pot
	bin/i18nextract --egg schooltool \
                        --domain schooltool.commendation \
                        --zcml schooltool/commendation/translations.zcml \
			--output-file build/schooltool/src/schooltool/commendation/locales/schooltool.commendation.pot
	bin/i18nextract --egg schooltool.gradebook \
	                --domain schooltool.gradebook \
	                --zcml schooltool/gradebook/translations.zcml \
                        --output-file build/schooltool.gradebook/src/schooltool/gradebook/locales/schooltool.gradebook.pot
	bin/i18nextract --egg schooltool.intervention \
	                --domain schooltool.intervention \
	                --zcml schooltool/intervention/translations.zcml \
                        --output-file build/schooltool.intervention/src/schooltool/intervention/locales/schooltool.intervention.pot
	bin/i18nextract --egg schooltool.lyceum.journal \
	                --domain schooltool.lyceum.journal \
	                --zcml schooltool/lyceum/journal/translations.zcml \
	                --output-file build/schooltool.lyceum.journal/src/schooltool/lyceum/journal/locales/schooltool.lyceum.journal.pot

.PHONY: compile-translations
compile-translations:
	set -e; \
	locales=build/schooltool/src/schooltool/locales; \
	for f in $${locales}/*.po; do \
	    mkdir -p $${f%.po}/LC_MESSAGES; \
	    msgfmt -o $${f%.po}/LC_MESSAGES/schooltool.mo $$f;\
	done
	locales=build/schooltool/src/schooltool/commendation/locales; \
	for f in $${locales}/*.po; do \
	    mkdir -p $${f%.po}/LC_MESSAGES; \
	    msgfmt -o $${f%.po}/LC_MESSAGES/schooltool.commendation.mo $$f;\
	done
	locales=build/schooltool.gradebook/src/schooltool/gradebook/locales; \
	for f in $${locales}/*.po; do \
	    mkdir -p $${f%.po}/LC_MESSAGES; \
	    msgfmt -o $${f%.po}/LC_MESSAGES/schooltool.gradebook.mo $$f;\
	done
	locales=build/schooltool.intervention/src/schooltool/intervention/locales; \
	for f in $${locales}/*.po; do \
	    mkdir -p $${f%.po}/LC_MESSAGES; \
	    msgfmt -o $${f%.po}/LC_MESSAGES/schooltool.intervention.mo $$f;\
	done
	locales=build/schooltool.lyceum.journal/src/schooltool/lyceum/journal/locales; \
	for f in $${locales}/*.po; do \
	    mkdir -p $${f%.po}/LC_MESSAGES; \
	    msgfmt -o $${f%.po}/LC_MESSAGES/schooltool.lyceum.journal.mo $$f;\
	done

.PHONY: update-translations
update-translations: extract-translations
	set -e; \
	locales=build/schooltool/src/schooltool/locales; \
	for f in $${locales}/*.po; do \
	    msgmerge -qU $$f $${locales}/schooltool.pot ;\
	done
	locales=build/schooltool/src/schooltool/commendation/locales; \
	for f in $${locales}/*.po; do \
	    msgmerge -qU $$f $${locales}/schooltool.commendation.pot ;\
	done
	locales=build/schooltool.gradebook/src/schooltool/gradebook/locales; \
	for f in $${locales}/*.po; do \
	    msgmerge -qU $$f $${locales}/schooltool.gradebook.pot ;\
	done
	locales=build/schooltool.intervention/src/schooltool/intervention/locales; \
	for f in $${locales}/*.po; do \
	    msgmerge -qU $$f $${locales}/schooltool.intervention.pot ;\
	done
	locales=build/schooltool.lyceum.journal/src/schooltool/lyceum/journal/locales; \
	for f in $${locales}/*.po; do \
	    msgmerge -qU $$f $${locales}/schooltool.lyceum.journal.pot ;\
	done
	$(MAKE) compile-translations

# Release

.PHONY: release
release: bin/buildout
	set -e
	@for package in $(PACKAGES) ; do \
	    echo -n `cat $${package}/version.txt.in`-r`bzr revno $${package}` > $${package}/version.txt ; \
	    bin/buildout setup $${package}/setup.py sdist ; \
	done

.PHONY: move-release
move-release:
	@if [ -w $(DIST) ] ; then { \
	    sh -c '(echo "[versions]" && ls build/*/dist/*.tar.gz | sed s/.tar.gz// | sed s/build\\/.*\\/// | sed s/-/" = "/) > trunk.cfg' ; \
	    mkdir -p $(DIST)/dev ; \
	    mv -fv trunk.cfg $(DIST)/dev ; \
	    for package in $(PACKAGES) ; do \
	        mv -v $${package}/dist/*.tar.gz $(DIST)/dev ; \
	    done; \
	    cp -uv versions.cfg $(DIST) ; \
	} fi

# Helpers

.PHONY: ubuntu-environment
ubuntu-environment:
	@if [ `whoami` != "root" ]; then { \
	 echo "You must be root to create an environment."; \
	 echo "I am running as $(shell whoami)"; \
	 exit 3; \
	} else { \
	 apt-get install bzr build-essential python-all python-all-dev libc6-dev libicu-dev; \
	 apt-get build-dep python-imaging; \
	 echo "Installation Complete: Next... Run 'make'."; \
	} fi

.PHONY: clean
clean:
	rm -rf python develop-eggs bin parts .installed.cfg

