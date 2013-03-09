#!/usr/bin/make

DIST=/home/ftp/pub/schooltool/flourish
PYTHON=python

INSTANCE_TYPE=schooltool
BUILDOUT_FLAGS=

PACKAGES=src/schooltool src/schooltool.gradebook src/schooltool.intervention src/schooltool.lyceum.journal src/schooltool.devtools src/schooltool.cando

.PHONY: all
all: build

.PHONY: build
build: .installed.cfg

python:
	rm -rf python
	virtualenv --no-site-packages -p $(PYTHON) python

.PHONY: bootstrap
bootstrap bin/buildout: python | buildout.cfg
	python/bin/python bootstrap.py --distribute

buildout.cfg:
	cp deploy.cfg buildout.cfg

.PHONY: buildout
buildout .installed.cfg: python bin/buildout buildout.cfg base.cfg deploy.cfg develop.cfg schooltool.cfg community.cfg versions.cfg
	bin/buildout $(BUILDOUT_FLAGS)

src/.bzr:
	bzr init-repo src

.PHONY: develop
develop bin/coverage bin/ctags: | src/.bzr buildout.cfg
	grep -q 'develop.cfg' buildout.cfg || sed -e 's/base.cfg/develop.cfg/' -i buildout.cfg
	$(MAKE) BUILDOUT_FLAGS=-n

$(PACKAGES): src/.bzr build
	@test -d $@ || bin/develop co `echo $@ | sed 's,src/,,g'`

.PHONY: update
update:
	test -x bin/develop || $(MAKE) BUILDOUT_FLAGS=-n
	bin/develop update --force
	$(MAKE) BUILDOUT_FLAGS=-n

instance: | build
	bin/make-schooltool-instance instance instance_type=$(INSTANCE_TYPE)

.PHONY: run
run: build instance
	bin/start-schooltool-instance instance

.PHONY: tags
tags: bin/ctags
	bin/ctags

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
	rm -f buildout.cfg
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
	rm -rf coverage
	bin/test --at-level 2 -u --coverage=$(CURDIR)/coverage

.PHONY: coverage-reports-html
coverage-reports-html coverage/reports: build
	test -d coverage || $(MAKE) coverage
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
	rm -rf ftest-coverage
	bin/test --at-level 2 -f --coverage=$(CURDIR)/ftest-coverage

.PHONY: ftest-coverage-reports-html
ftest-coverage-reports-html ftest-coverage/reports: build
	test -d ftest-coverage || $(MAKE) ftest-coverage
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
	locales=src/schooltool.cando/src/schooltool/cando/locales; \
	for f in $${locales}/*.po; do \
	    mkdir -p $${f%.po}/LC_MESSAGES; \
	    msgfmt -o $${f%.po}/LC_MESSAGES/schooltool.cando.mo $$f;\
	done

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

.PHONY: upload
upload:
	scp versions.cfg schooltool.org:$(DIST)

# Helpers

.PHONY: ubuntu-environment
ubuntu-environment:
	sudo apt-get install bzr build-essential gettext enscript \
	    python-dev python-virtualenv \
	    ttf-ubuntu-font-family ttf-liberation \
	    libicu-dev libxslt1-dev libfreetype6-dev libjpeg-dev

