# Adapted from: http://www.greghendershott.com/2017/04/racket-makefiles.html
PACKAGE-NAME=qi

DEPS-FLAGS=--check-pkg-deps --unused-pkg-deps

help:
	@echo "install - install package along with dependencies"
	@echo "remove - remove package"
	@echo "build - Compile libraries"
	@echo "build-docs - Build docs"
	@echo "build-all - Compile libraries, build docs, and check dependencies"
	@echo "clean - remove all build artifacts"
	@echo "check-deps - check dependencies"
	@echo "test - run tests"
	@echo "test-with-errortrace - run tests with error tracing"
	@echo "errortrace - alias for test-with-errortrace"
	@echo "cover - Run test coverage checker and view report"
	@echo "cover-coveralls - Run test coverage and upload to Coveralls"
	@echo "coverage-check - Run test coverage checker"
	@echo "coverage-report - View test coverage report"
	@echo "docs - view docs in a browser"

# Primarily for use by CI.
# Installs dependencies as well as linking this as a package.
install:
	raco pkg install --deps search-auto --link $(PWD)/$(PACKAGE-NAME)-{lib,test,doc} $(PWD)/$(PACKAGE-NAME)

remove:
	raco pkg remove $(PACKAGE-NAME)-{lib,test,doc} $(PACKAGE-NAME)

# Primarily for day-to-day dev.
# Build libraries from source.
build:
	raco setup --no-docs --tidy --pkgs $(PACKAGE-NAME)-lib

# Primarily for day-to-day dev.
# Build docs (if any).
build-docs:
	raco setup --no-launcher --no-foreign-libs --no-info-domain --no-pkg-deps \
	--no-install --no-post-install --tidy --pkgs $(PACKAGE-NAME)-doc

# Primarily for day-to-day dev.
# Build libraries from source, build docs (if any), and check dependencies.
build-all:
	raco setup --tidy $(DEPS-FLAGS) --pkgs $(PACKAGE-NAME)

# Note: Each collection's info.rkt can say what to clean, for example
# (define clean '("compiled" "doc" "doc/<collect>")) to clean
# generated docs, too.
clean:
	raco setup --fast-clean --pkgs $(PACKAGE-NAME)-{lib,test,doc}

# Primarily for use by CI, after make install -- since that already
# does the equivalent of make setup, this tries to do as little as
# possible except checking deps.
check-deps:
	raco setup --no-docs $(DEPS-FLAGS) $(PACKAGE-NAME)

# Suitable for both day-to-day dev and CI
test:
	raco test -exp $(PACKAGE-NAME)-{lib,test,doc}

test-with-errortrace:
	racket -l errortrace -l racket -e '(require (submod "qi-test/tests/qi.rkt" test))'

errortrace: test-with-errortrace

docs:
	raco docs $(PACKAGE-NAME)

coverage-check:
	raco cover -b -n dev -p $(PACKAGE-NAME)-{lib,test}

coverage-report:
	open coverage/index.html

cover: coverage-check coverage-report

cover-coveralls:
	raco cover -b -n dev -f coveralls -p $(PACKAGE-NAME)-{lib,test}

profile-forms:
	echo "Profiling forms..."
	racket dev/profile/forms.rkt

profile-base:
	echo "Running base smoke profilers..."
	racket dev/profile/base.rkt

profile: profile-base profile-forms

.PHONY:	help install remove build build-docs build-all clean check-deps test test-with-errortrace errortrace docs cover coverage-check coverage-report cover-coveralls profile
