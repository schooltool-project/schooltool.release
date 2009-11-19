#!/usr/bin/make
#
# Makefile for SchoolTool trunk buildbot
#

BOOTSTRAP_PYTHON=python2.5
SCHOOLTOOL_BZR='http://source.schooltool.org/var/local/bzr/schooltool'
LP='http://bazaar.launchpad.net/~schooltool-owners'
DIST='/home/ftp/pub/schooltool/1.2'

.PHONY: all
all: bin/test-all

# Sandbox

.PHONY: bootstrap
bootstrap: build/schooltool build/schooltool.gradebook build/schooltool.intervention build/schooltool.lyceum.journal build/schooltool.cas build/schooltool.stapp2008fall
	$(BOOTSTRAP_PYTHON) bootstrap.py

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

bin/buildout: build/schooltool build/schooltool.gradebook build/schooltool.intervention build/schooltool.lyceum.journal build/schooltool.cas build/schooltool.stapp2008fall
	test -d python -a -f bin/buildout || $(BOOTSTRAP_PYTHON) bootstrap.py

bin/test-all: bin/buildout
	bin/buildout

bin/test-schooltool: bin/buildout
	bin/buildout

bin/test-gradebook: bin/buildout
	bin/buildout

bin/test-intervention: bin/buildout
	bin/buildout

bin/test-journal: bin/buildout
	bin/buildout

bin/coverage:
	bin/buildout

.PHONY: buildout
buildout: bin/buildout
	bin/buildout

.PHONY: bzrupdate
bzrupdate:
	bzr up build/schooltool
	bzr up build/schooltool.gradebook
	bzr up build/schooltool.intervention
	bzr up build/schooltool.lyceum.journal
	bzr up build/schooltool.cas
	bzr up build/schooltool.stapp2008fall

.PHONY: update
update: bin/buildout bzrupdate
	bin/buildout -n
	test -w $(DIST) && cp -uv versions.cfg $(DIST) || true

# Tests

.PHONY: test
test: bin/test-all
	bin/test-all --at-level 2 -u

.PHONY: ftest
ftest: bin/test-all
	bin/test-all --at-level 2 -f

# Coverage

.PHONY: coverage
coverage: bin/test-all
	test -d parts/test-all/coverage && ! test -d coverage && mv parts/test-all/coverage . || true
	rm -rf coverage
	bin/test-all --at-level 2 -u --coverage=coverage
	mv parts/test-all/coverage .

.PHONY: coverage-reports-html
coverage-reports-html coverage/reports: bin/coverage
	test -d parts/test-all/coverage && ! test -d coverage && mv parts/test-all/coverage . || true
	rm -rf coverage/reports
	mkdir coverage/reports
	bin/coverage coverage coverage/reports
	ln -s schooltool.html coverage/reports/index.html

.PHONY: ftest-coverage
ftest-coverage: bin/test-all
	test -d parts/test-all/ftest-coverage && ! test -d ftest-coverage && mv parts/test-all/ftest-coverage . || true
	rm -rf ftest-coverage
	bin/test-all --at-level 2 -f --coverage=ftest-coverage
	mv parts/test-all/ftest-coverage .

.PHONY: ftest-coverage-reports-html
ftest-coverage-reports-html ftest-coverage/reports: bin/coverage
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
	locales=build/schooltool.lyceum.journal/src/schooltool/lyceum/journal/locales; \
	for f in $${locales}/*.po; do \
	    msgmerge -qU $$f $${locales}/schooltool.lyceum.journal.pot ;\
	done
	$(MAKE) PYTHON=$(PYTHON) compile-translations

# Release

.PHONY: release
release: bin/buildout
	release=build/schooltool; \
	echo -n `sed -e 's/\n//' $${release}/version.txt.in` > $${release}/version.txt; \
	echo -n "_r" >> $${release}/version.txt; \
	bzr revno $${release} >> $${release}/version.txt; \
	bin/buildout setup $${release}/setup.py sdist
	release=build/schooltool.gradebook; \
	echo -n `sed -e 's/\n//' $${release}/version.txt.in` > $${release}/version.txt; \
	echo -n "_r" >> $${release}/version.txt; \
	bzr revno $${release} >> $${release}/version.txt; \
	bin/buildout setup $${release}/setup.py sdist
	release=build/schooltool.intervention; \
	echo -n `sed -e 's/\n//' $${release}/version.txt.in` > $${release}/version.txt; \
	echo -n "_r" >> $${release}/version.txt; \
	bzr revno $${release} >> $${release}/version.txt; \
	bin/buildout setup $${release}/setup.py sdist
	release=build/schooltool.lyceum.journal; \
	echo -n `sed -e 's/\n//' $${release}/version.txt.in` > $${release}/version.txt; \
	echo -n "_r" >> $${release}/version.txt; \
	bzr revno $${release} >> $${release}/version.txt; \
	bin/buildout setup $${release}/setup.py sdist
	bin/buildout setup build/schooltool.cas/setup.py sdist
	bin/buildout setup build/schooltool.stapp2008fall/setup.py sdist

.PHONY: move-release
move-release:
	sh -c '(echo "[versions]" && ls build/*/dist/*.tar.gz | sed s/.tar.gz// | sed s/build\\/.*\\/// | sed s/-/" = "/) > trunk.cfg'
	mv -fv trunk.cfg /home/ftp/pub/schooltool/releases/nightly/
	package=schooltool; \
	mv -v build/$${package}/dist/$${package}-*.tar.gz /home/ftp/pub/schooltool/releases/nightly
	package=schooltool.gradebook; \
	mv -v build/$${package}/dist/$${package}-*.tar.gz /home/ftp/pub/schooltool/releases/nightly
	package=schooltool.intervention; \
	mv -v build/$${package}/dist/$${package}-*.tar.gz /home/ftp/pub/schooltool/releases/nightly
	package=schooltool.lyceum.journal; \
	mv -v build/$${package}/dist/$${package}-*.tar.gz /home/ftp/pub/schooltool/releases/nightly
	package=schooltool.cas; \
	mv -v build/$${package}/dist/$${package}-*.tar.gz /home/ftp/pub/schooltool/releases/nightly
	package=schooltool.stapp2008fall; \
	mv -v build/$${package}/dist/$${package}-*.tar.gz /home/ftp/pub/schooltool/releases/nightly

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

