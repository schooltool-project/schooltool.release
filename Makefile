#!/usr/bin/make
#
# Makefile for 2008.04 buildbot
#

BOOTSTRAP_PYTHON=python2.4

.PHONY: all
all: bin/test-all

# Sandbox

.PHONY: bootstrap
bootstrap: build/schooltool build/schooltool.gradebook build/schooltool.lyceum.journal build/schooltool.ldap build/schooltool.cas build/schooltool.stapp2008fall build/schooltool.stapp2008spring
	$(BOOTSTRAP_PYTHON) bootstrap.py

build/.bzr:
	bzr init-repo build

build/schooltool: build/.bzr
	bzr co http://staging.schooltool.org/bzr2/schooltool/schooltool/trunk/ build/schooltool

build/schooltool.gradebook: build/.bzr
	bzr co http://staging.schooltool.org/bzr2/schooltool/schooltool.gradebook/trunk/ build/schooltool.gradebook

build/schooltool.lyceum.journal: build/.bzr
	bzr co http://staging.schooltool.org/bzr2/schooltool/schooltool.lyceum.journal/trunk/ build/schooltool.lyceum.journal

build/schooltool.stapp2008spring: build/.bzr
	bzr co http://staging.schooltool.org/bzr2/schooltool/schooltool.stapp2008spring/trunk/ build/schooltool.stapp2008spring

build/schooltool.stapp2008fall: build/.bzr
	bzr co http://staging.schooltool.org/bzr2/schooltool/schooltool.stapp2008fall/trunk/ build/schooltool.stapp2008fall

build/schooltool.cas: build/.bzr
	bzr co http://staging.schooltool.org/bzr2/schooltool/schooltool.cas/trunk/ build/schooltool.cas

build/schooltool.ldap: build/.bzr
	bzr co http://staging.schooltool.org/bzr2/schooltool/schooltool.ldap/trunk/ build/schooltool.ldap

bin/buildout: build/schooltool build/schooltool.gradebook build/schooltool.lyceum.journal build/schooltool.ldap build/schooltool.cas build/schooltool.stapp2008fall build/schooltool.stapp2008spring
	$(BOOTSTRAP_PYTHON) bootstrap.py

bin/test-all: bin/buildout
	bin/buildout

bin/test-schooltool: bin/buildout
	bin/buildout

bin/test-gradebook: bin/buildout
	bin/buildout

bin/test-journal: bin/buildout
	bin/buildout

bin/coverage:
	bin/buildout

.PHONY: buildout
buildout: bin/buildout
	bin/buildout

.PHONY: update
update: bin/buildout
	bzr up build/schooltool
	bzr up build/schooltool.gradebook
	bzr up build/schooltool.lyceum.journal
	bzr up build/schooltool.ldap
	bzr up build/schooltool.cas
	bzr up build/schooltool.stapp2008fall
	bzr up build/schooltool.stapp2008spring
	bin/buildout -n

# Tests

.PHONY: test
test: bin/test-all
	bin/test-all -uf --at-level 2
	bin/test-schooltool
	bin/test-gradebook
	bin/test-journal
	bin/test-ldap
	bin/test-cas
	bin/test-stapp2008fall
	bin/test-stapp2008spring

.PHONY: ftest
ftest:
	echo "Pass"

# Coverage

.PHONY: coverage
coverage: bin/test-all
	rm -rf coverage
	bin/test-all -u --coverage=coverage
	mv parts/test-all/coverage .
	@cd coverage && ls | grep -v tests | xargs grep -c '^>>>>>>' | grep -v ':0$$'

.PHONY: coverage-reports-html
coverage-reports-html: bin/coverage
	rm -rf coverage/reports
	mkdir coverage/reports
	bin/coverage
	ln -s schooltool.html coverage/reports/index.html

# Release

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
	bin/i18nextract --egg schooltool.lyceum.journal \
			 --domain schooltool.lyceum.journal \
			 --zcml schooltool/lyceum/journal/translation.zcml \
			 --output-file build/schooltool.lyceum.journal/src/schooltool/lyceum/journal/locales/schooltool.lyceum.journal.pot

.PHONY: compile-translations
compile-translations:
	set -e; \
	locales=build/schooltool/src/schooltool/locales; \
	for f in $${locales}/*/LC_MESSAGES/schooltool.po; do \
	    msgfmt -o $${f%.po}.mo $$f;\
	done
	locales=build/schooltool/src/schooltool/commendation/locales; \
	for f in $${locales}/*/LC_MESSAGES/schooltool.commendation.po; do \
	    msgfmt -o $${f%.po}.mo $$f;\
	done
	set -e; \
	locales=build/schooltool.lyceum.journal/src/schooltool/lyceum/journal/locales; \
	for f in $${locales}/*/LC_MESSAGES/schooltool.lyceum.journal.po; do \
	    msgfmt -o $${f%.po}.mo $$f;\
	done

.PHONY: update-translations
update-translations: extract-translations
	set -e; \
	locales=build/schooltool/src/schooltool/commendation/locales; \
	for f in $${locales}/*/LC_MESSAGES/schooltool.commendation.po; do \
	    msgmerge -qU $$f $${locales}/schooltool.commendation.pot ;\
	done
	locales=build/schooltool/src/schooltool/locales; \
	for f in $${locales}/*/LC_MESSAGES/schooltool.po; do \
	    msgmerge -qU $$f $${locales}/schooltool.pot ;\
	done
	locales=build/schooltool.lyceum.journal/src/schooltool/lyceum/journal/locales; \
	for f in $${locales}/*/LC_MESSAGES/schooltool.lyceum.journal.po; do \
	    msgmerge -qU $$f $${locales}/schooltool.lyceum.journal.pot ;\
	done
	$(MAKE) PYTHON=$(PYTHON) compile-translations

.PHONY: release
release: compile-translations bin/buildout
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
	release=build/schooltool.lyceum.journal; \
	echo -n `sed -e 's/\n//' $${release}/version.txt.in` > $${release}/version.txt; \
	echo -n "_r" >> $${release}/version.txt; \
	bzr revno $${release} >> $${release}/version.txt; \
	bin/buildout setup $${release}/setup.py sdist
	bin/buildout setup build/schooltool.ldap/setup.py sdist
	bin/buildout setup build/schooltool.cas/setup.py sdist
	bin/buildout setup build/schooltool.stapp2008fall/setup.py sdist
	bin/buildout setup build/schooltool.stapp2008spring/setup.py sdist

.PHONY: move-release
move-release:
	package=schooltool; \
	mv -v build/$${package}/dist/$${package}-*.tar.gz /home/ftp/pub/schooltool/releases/nightly
	package=schooltool.gradebook; \
	mv -v build/$${package}/dist/$${package}-*.tar.gz /home/ftp/pub/schooltool/releases/nightly
	package=schooltool.lyceum.journal; \
	mv -v build/$${package}/dist/$${package}-*.tar.gz /home/ftp/pub/schooltool/releases/nightly
	package=schooltool.ldap; \
	mv -v build/$${package}/dist/$${package}-*.tar.gz /home/ftp/pub/schooltool/releases/nightly
	package=schooltool.cas; \
	mv -v build/$${package}/dist/$${package}-*.tar.gz /home/ftp/pub/schooltool/releases/nightly
	package=schooltool.stapp2008fall; \
	mv -v build/$${package}/dist/$${package}-*.tar.gz /home/ftp/pub/schooltool/releases/nightly
	package=schooltool.stapp2008spring; \
	mv -v build/$${package}/dist/$${package}-*.tar.gz /home/ftp/pub/schooltool/releases/nightly

# Helpers

.PHONY: ubuntu-environment
ubuntu-environment:
	@if [ `whoami` != "root" ]; then { \
	 echo "You must be root to create an environment."; \
	 echo "I am running as $(shell whoami)"; \
	 exit 3; \
	} else { \
	 apt-get install subversion build-essential python-all python-all-dev libc6-dev libicu-dev; \
	 apt-get build-dep python-imaging; \
	 apt-get build-dep python-libxml2 libxml2; \
	 echo "Installation Complete: Next... Run 'make'."; \
	} fi

.PHONY: clean
clean:
	rm -rf python develop-eggs bin parts .installed.cfg build/*


