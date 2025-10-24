# Adapted from: http://www.greghendershott.com/2017/04/racket-makefiles.html
SHELL=/bin/bash

PACKAGE-NAME=qi

DEPS-FLAGS=--check-pkg-deps --unused-pkg-deps

help:
	@echo "Run common development actions."
	@echo
	@echo "    Usage: make <target>"
	@echo "    where <target> is one of:"
	@echo
	@echo "help - show this menu"
	@echo "install - install package along with dependencies"
	@echo "install-sdk - install the SDK which includes developer tools"
	@echo "remove - remove package"
	@echo "remove-sdk - remove SDK; this will not remove SDK dependencies"
	@echo "build - Compile libraries"
	@echo "build-docs - Build docs"
	@echo "build-standalone-docs - Build self-contained docs that could be hosted somewhere"
	@echo "build-all - Compile libraries, build docs, and check dependencies"
	@echo "clean - remove all build artifacts"
	@echo "clean-sdk - remove all build artifacts in SDK paths"
	@echo "check-deps - check dependencies"
	@echo "test - run tests"
	@echo "test-with-errortrace - run tests with error tracing"
	@echo "errortrace - alias for test-with-errortrace"
	@echo "test-<module> - Run tests for <module>"
	@echo "errortrace-<module> - Run tests for <module> with error tracing"
	@echo "Modules:"
	@echo "  flow"
	@echo "  on"
	@echo "  threading"
	@echo "  switch"
	@echo "  definitions"
	@echo "  macro"
	@echo "  util"
	@echo "  expander"
	@echo "  compiler"
	@echo "  probe"
	@echo "    Note: As probe is not in qi-lib, it isn't part of"
	@echo "    the tests run in the 'test' target."
	@echo "cover - Run test coverage checker and view report"
	@echo "cover-coveralls - Run test coverage and upload to Coveralls"
	@echo "coverage-check - Run test coverage checker"
	@echo "coverage-report - View test coverage report"
	@echo "docs - view docs in a browser"
	@echo "new-benchmarks - Run new benchmarks and generate an HTML report"
	@echo "profile - Get a performance profile of any Racket command"
	@echo "benchmark - Run comprehensive performance benchmarks"
	@echo "benchmark-competitive - Run competitive benchmarks"
	@echo "benchmark-local - Run benchmarks for individual Qi forms"
	@echo "benchmark-nonlocal - Run nonlocal benchmarks exercising many components at once"
	@echo "benchmark-selected-forms - Run benchmarks for Qi forms by name (command only)"
	@echo "performance-report - Run benchmarks for Qi forms and produce results for use in CI and for measuring regression"
	@echo "  For use in regression: make performance-report > /path/to/before.json"
	@echo "performance-regression-report - Run benchmarks for Qi forms against a reference report."
	@echo "  make performance-regression-report REF=/path/to/before.json"


# Primarily for use by CI.
# Installs dependencies as well as linking this as a package.
install:
	raco pkg install --deps search-auto --link $(PWD)/$(PACKAGE-NAME)-{lib,test,doc,probe,redex} $(PWD)/$(PACKAGE-NAME)

install-sdk:
	raco pkg install --deps search-auto --link $(PWD)/$(PACKAGE-NAME)-sdk

remove:
	raco pkg remove $(PACKAGE-NAME)-{lib,test,doc,probe,redex} $(PACKAGE-NAME)

remove-sdk:
	raco pkg remove $(PACKAGE-NAME)-sdk

# Primarily for day-to-day dev.
# Build libraries from source.
# Note that  `raco setup --pkgs qi-lib` ends up building
# the entire `qi` collection and takes a long time, so we
# use `raco make -l <module>` here instead.
# See https://github.com/racket/racket/issues/5129
build:
	raco make -l qi -v

# Primarily for day-to-day dev.
# Build docs (if any).
build-docs:
	raco setup --no-launcher --no-foreign-libs --no-info-domain --no-pkg-deps \
	--no-install --no-post-install --pkgs $(PACKAGE-NAME)-doc

# Primarily for day-to-day dev.
# Build libraries from source, build docs (if any), and check dependencies.
build-all:
	raco setup $(DEPS-FLAGS) --pkgs $(PACKAGE-NAME)-{lib,test,doc,probe,redex} $(PACKAGE-NAME)

# Primarily for CI, for building backup docs that could be used in case
# the main docs at docs.racket-lang.org become unavailable.
build-standalone-docs:
	scribble +m --redirect-main http://pkg-build.racket-lang.org/doc/ --htmls --dest ./docs ./qi-doc/scribblings/qi.scrbl

build-sdk:
	raco setup --no-docs --pkgs $(PACKAGE-NAME)-sdk

# Note: Each collection's info.rkt can say what to clean, for example
# (define clean '("compiled" "doc" "doc/<collect>")) to clean
# generated docs, too.
clean:
	raco setup --fast-clean --pkgs $(PACKAGE-NAME)-{lib,test,doc,probe,redex}

clean-sdk:
	raco setup --fast-clean --pkgs $(PACKAGE-NAME)-sdk

# Primarily for use by CI, after make install -- since that already
# does the equivalent of make setup, this tries to do as little as
# possible except checking deps.
check-deps:
	raco setup --no-docs $(DEPS-FLAGS) $(PACKAGE-NAME)

test-all: test test-probe test-redex

# Suitable for both day-to-day dev and CI
# Note: we don't test qi-doc since there aren't any tests there atm
# and it also seems to make things extremely slow to include it.
test: build
	raco make -l qi/tests/qi -v
	raco test -exp $(PACKAGE-NAME)-{lib,test}

test-flow:
	racket -y $(PACKAGE-NAME)-test/tests/flow.rkt

test-list:
	racket -y $(PACKAGE-NAME)-test/tests/list.rkt

test-on:
	racket -y $(PACKAGE-NAME)-test/tests/on.rkt

test-threading:
	racket -y $(PACKAGE-NAME)-test/tests/threading.rkt

test-switch:
	racket -y $(PACKAGE-NAME)-test/tests/switch.rkt

test-definitions:
	racket -y $(PACKAGE-NAME)-test/tests/definitions.rkt

test-macro:
	racket -y $(PACKAGE-NAME)-test/tests/macro.rkt

test-util:
	racket -y $(PACKAGE-NAME)-test/tests/util.rkt

test-expander:
	racket -y $(PACKAGE-NAME)-test/tests/expander.rkt

test-compiler:
	racket -y $(PACKAGE-NAME)-test/tests/compiler.rkt

test-probe:
	raco test -exp $(PACKAGE-NAME)-probe

test-redex:
	raco test -exp $(PACKAGE-NAME)-redex

test-with-errortrace:
	racket -l errortrace -l racket -e '(require (submod "$(PACKAGE-NAME)-test/tests/qi.rkt" test))'

errortrace: test-with-errortrace

errortrace-flow:
	racket -l errortrace -l racket -e '(require (submod "$(PACKAGE-NAME)-test/tests/flow.rkt" main))'

errortrace-on:
	racket -l errortrace -l racket -e '(require (submod "$(PACKAGE-NAME)-test/tests/on.rkt" main))'

errortrace-threading:
	racket -l errortrace -l racket -e '(require (submod "$(PACKAGE-NAME)-test/tests/threading.rkt" main))'

errortrace-switch:
	racket -l errortrace -l racket -e '(require (submod "$(PACKAGE-NAME)-test/tests/switch.rkt" main))'

errortrace-definitions:
	racket -l errortrace -l racket -e '(require (submod "$(PACKAGE-NAME)-test/tests/definitions.rkt" main))'

errortrace-macro:
	racket -l errortrace -l racket -e '(require (submod "$(PACKAGE-NAME)-test/tests/macro.rkt" main))'

errortrace-util:
	racket -l errortrace -l racket -e '(require (submod "$(PACKAGE-NAME)-test/tests/util.rkt" main))'

errortrace-probe:
	racket -l errortrace -l racket -e '(require (submod "$(PACKAGE-NAME)-probe/tests/qi-probe.rkt" test))'

docs:
	raco docs $(PACKAGE-NAME)

coverage-check:
	raco cover -b -d ./coverage -p $(PACKAGE-NAME)-{lib,test}

coverage-report:
	open coverage/index.html

cover: coverage-check coverage-report

cover-coveralls:
	raco cover -b -f coveralls -p $(PACKAGE-NAME)-{lib,test}

profile:
	@echo "To get a performance profile:"
	@echo "  raco profile --total <any Racket command, including arguments>"
	@echo "Example:"
	@echo "  raco profile --total qi-sdk/benchmarks/nonlocal/report-competitive.rkt -s filter-map"
	@echo "For more options:"
	@echo "  raco profile --help"

new-benchmarks:
	cd qi-sdk/benchmarks/competitive && \
	scribble \
		++convert svg \
		++arg -p \
		++arg github \
		--html \
		--dest results \
		--dest-name index.html \
		report.scrbl

new-benchmarks-preview:
	cd qi-sdk/benchmarks/competitive && \
	scribble \
		++convert svg \
		++arg -p \
		++arg preview \
		--html \
		--dest results \
		--dest-name index.html \
		report.scrbl

benchmark-local:
	racket $(PACKAGE-NAME)-sdk/benchmarks/local/report.rkt

benchmark-loading:
	racket $(PACKAGE-NAME)-sdk/benchmarks/loading/report.rkt

benchmark-selected-forms:
	@echo "Use 'racket $(PACKAGE-NAME)-sdk/benchmarks/local/report.rkt' directly, with -s form-name for each form."

benchmark-competitive:
	cd $(PACKAGE-NAME)-sdk/benchmarks/nonlocal; racket report-competitive.rkt

benchmark-nonlocal:
	cd $(PACKAGE-NAME)-sdk/benchmarks/nonlocal; racket report-intrinsic.rkt -l qi

benchmark: benchmark-local benchmark-nonlocal benchmark-loading

performance-report:
	@racket $(PACKAGE-NAME)-sdk/benchmarks/report.rkt -f json

performance-regression-report:
	@racket $(PACKAGE-NAME)-sdk/benchmarks/report.rkt -r $(REF)

.PHONY:	help install remove build build-docs build-all clean check-deps test-all test test-flow test-on test-threading test-switch test-definitions test-macro test-util test-expander test-compiler test-probe test-with-errortrace errortrace errortrace-flow errortrace-on errortrace-threading errortrace-switch errortrace-definitions errortrace-macro errortrace-util errortrace-probe docs cover coverage-check coverage-report cover-coveralls profile new-benchmarks new-benchmarks-preview benchmark-local benchmark-loading benchmark-selected-forms benchmark-competitive benchmark-nonlocal benchmark performance-report performance-regression-report
