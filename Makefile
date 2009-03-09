#!/usr/bin/make
#
# Makefile for 2008.04 buildbot
#

BOOTSTRAP_PYTHON=python2.4

.PHONY: all
all: bin/test-all

# Sandbox

.PHONY: bootstrap
bootstrap:
	$(BOOTSTRAP_PYTHON) bootstrap.py

build/.bzr:
	bzr init-repo build

build/schooltool: build/.bzr
	bzr co http://staging.schooltool.org/bzr2/schooltool/schooltool/branches/2008.04/ build/schooltool

build/schooltool.gradebook: build/.bzr
	bzr co http://staging.schooltool.org/bzr2/schooltool/schooltool.gradebook/branches/0.2/ build/schooltool.gradebook

build/schooltool.lyceum.journal: build/.bzr
	bzr co http://staging.schooltool.org/bzr2/schooltool/schooltool.lyceum.journal/branches/0.1/ build/schooltool.lyceum.journal

bin/buildout: build/schooltool build/schooltool.gradebook build/schooltool.lyceum.journal
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
	bin/buildout -n
	bzr up build/schooltool
	bzr up build/schooltool.gradebook
	bzr up build/schooltool.lyceum.journal

# Tests

.PHONY: test
test: bin/test-all
	bin/test-all -uf --at-level 2

# Coverage

.PHONY: coverage
coverage: bin/test-all
	rm -rf coverage
	bin/test-all -u --coverage=coverage
	mv parts/test/coverage .
	@cd coverage && ls | grep -v tests | xargs grep -c '^>>>>>>' | grep -v ':0$$'

.PHONY: coverage-reports-html
coverage-reports-html: bin/coverage
	rm -rf coverage/reports
	mkdir coverage/reports
	bin/coverage
	ln -s lyceum.html coverage/reports/index.html

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
	locales=src/schooltool/commendation/locales; \
	for f in $${locales}/*/LC_MESSAGES/schooltool.commendation.po; do \
	    msgmerge -qU $$f $${locales}/schooltool.commendation.pot ;\
	done
	locales=src/schooltool/locales; \
	for f in $${locales}/*/LC_MESSAGES/schooltool.po; do \
	    msgmerge -qU $$f $${locales}/schooltool.pot ;\
	done
	locales=build/schooltool.lyceum.journal/src/schooltool/lyceum/journal/locales; \
	for f in $${locales}/*/LC_MESSAGES/schooltool.lyceum.journal.po; do \
	    msgmerge -qU $$f $${locales}/schooltool.lyceum.journal.pot ;\
	done
	$(MAKE) PYTHON=$(PYTHON) compile-translations

.PHONY: release
release: compile-translations
	echo -n `sed -e 's/\n//' version.txt.in` > version.txt
	echo -n "_r" >> version.txt
	bzr revno >> version.txt
	bin/buildout setup setup.py sdist

.PHONY: move-release
move-release:
	 mv dist/schooltool-*.tar.gz /home/ftp/pub/schooltool/releases/nightly

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



###
# To release:
#   make bootstrap
#   make release
#   make move-release
#
# To test:
#   make
#   make update
#   make test


