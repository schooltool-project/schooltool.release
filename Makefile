#!/usr/bin/make
#
# Makefile for 2008.04 buildbot
#

BOOTSTRAP_PYTHON=python2.4

.PHONY: all
all: bin/test-all

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

.PHONY: test
test: bin/test-all
	bin/test-all -uf --at-level 2

.PHONY: clean
clean:
	rm -rf python develop-eggs bin parts .installed.cfg build/*

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

