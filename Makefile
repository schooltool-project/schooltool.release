#!/usr/bin/make
#
# Makefile for SchoolTool Release
#

DIST=/home/ftp/pub/schooltool/trunk
BOOTSTRAP_PYTHON=python

INSTANCE_TYPE=schooltool
BUILDOUT_FLAGS=

PACKAGES=src/schooltool src/schooltool.gradebook src/schooltool.intervention src/schooltool.lyceum.journal

.PHONY: all
all: build

.PHONY: build
build: .installed.cfg

.PHONY: bootstrap
bootstrap bin/buildout python:
	$(BOOTSTRAP_PYTHON) bootstrap.py

.PHONY: buildout
buildout .installed.cfg: python bin/buildout buildout.cfg schooltool.cfg community.cfg versions.cfg
	bin/buildout $(BUILDOUT_FLAGS)

src/.bzr:
	bzr init-repo src

.PHONY: develop
develop: src/.bzr
	$(MAKE) buildout BUILDOUT_FLAGS='-c development.cfg'

$(PACKAGES): src/.bzr build
	@test -d $@ || bin/develop co `echo $@ | sed 's,src/,,g'`

.PHONY: update
update: build
	bin/develop update
	bin/develop rebuild

instance: | build
	bin/make-schooltool-instance instance instance_type=$(INSTANCE_TYPE)

.PHONY: run
run: build instance
	bin/start-schooltool-instance instance

.PHONY: tags
tags: build
	bin/tags

.PHONY: clean
clean:
	rm -rf python
	rm -rf bin develop-eggs parts .installed.cfg
	rm -rf build
	rm -f ID TAGS tags
	rm -rf coverage ftest-coverage
	find . -name '*.py[co]' -delete
	find . -name '*.mo' -delete
	find . -name 'LC_MESSAGES' -exec rmdir -p --ignore-fail-on-non-empty {} +

.PHONY: realclean
realclean:
	rm -rf eggs
	rm -rf dist
	rm -rf instance
	$(MAKE) clean

# Tests

.PHONY: test
test: build
	bin/test --at-level 2 -u

.PHONY: ftest
ftest: build
	bin/test --at-level 2 -f

.PHONY: testall
testall: build
	bin/test --at-level 2

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
extract-translations: build $(PACKAGES)
	bin/i18nextract --egg schooltool \
	                --domain schooltool \
	                --zcml schooltool/common/translations.zcml \
	                --output-file src/schooltool/src/schooltool/locales/schooltool.pot
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
compile-translations: $(PACKAGES)
	set -e; \
	locales=src/schooltool/src/schooltool/locales; \
	for f in $${locales}/*.po; do \
	    mkdir -p $${f%.po}/LC_MESSAGES; \
	    msgfmt -o $${f%.po}/LC_MESSAGES/schooltool.mo $$f;\
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
update-translations:
	set -e; \
	locales=src/schooltool/src/schooltool/locales; \
	for f in $${locales}/*.po; do \
	    msgmerge -qUFN $$f $${locales}/schooltool.pot ;\
	done
	locales=src/schooltool.gradebook/src/schooltool/gradebook/locales; \
	for f in $${locales}/*.po; do \
	    msgmerge -qUFN $$f $${locales}/schooltool.gradebook.pot ;\
	done
	locales=src/schooltool.intervention/src/schooltool/intervention/locales; \
	for f in $${locales}/*.po; do \
	    msgmerge -qUFN $$f $${locales}/schooltool.intervention.pot ;\
	done
	locales=src/schooltool.lyceum.journal/src/schooltool/lyceum/journal/locales; \
	for f in $${locales}/*.po; do \
	    msgmerge -qUFN $$f $${locales}/schooltool.lyceum.journal.pot ;\
	done
	$(MAKE) compile-translations

# Release

.PHONY: release
release: bin/buildout compile-translations
	set -e
	@for package in $(PACKAGES) ; do \
	    version=`cat $${package}/version.txt.in`-r`bzr revno $${package}` ; \
	    echo -n $${version} > $${package}/version.txt ; \
	    bin/buildout setup $${package}/setup.py sdist ; \
	    rm -f $${package}/version.txt ; \
	done

.PHONY: move-release
move-release:
	test -w $(DIST)
	mkdir -p $(DIST)/dev
	@for package in $(PACKAGES) ; do \
	    version=`cat $${package}/version.txt.in`-r`bzr revno $${package}` ; \
	    mv -v $${package}/dist/*-$${version}.tar.gz $(DIST)/dev ; \
	done
	cp -uv versions.cfg $(DIST)

# Helpers

.PHONY: ubuntu-environment
ubuntu-environment:
	sudo apt-get install bzr build-essential gettext enscript ttf-liberation \
	    python-all-dev libc6-dev libicu-dev libxslt1-dev libfreetype6-dev libjpeg62-dev 

