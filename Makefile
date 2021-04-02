# Adapted from: http://www.greghendershott.com/2017/04/racket-makefiles.html
PACKAGE-NAME=on-macro
COLLECTION-NAME=syntax/on

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
	@echo "coverage-check - Run test coverage checker"
	@echo "coverage-report - View test coverage report"
	@echo "docs - view docs in a browser"

# Primarily for use by CI.
# Installs dependencies as well as linking this as a package.
install:
	raco pkg install --deps search-auto

remove:
	raco pkg remove $(PACKAGE-NAME)

# Primarily for day-to-day dev.
# Build libraries from source.
build:
	raco setup --no-docs --tidy $(COLLECTION-NAME)

# Primarily for day-to-day dev.
# Build docs (if any).
build-docs:
	raco setup --no-launcher --no-foreign-libs --no-info-domain --no-pkg-deps \
	--no-install --no-post-install --tidy $(COLLECTION-NAME)

# Primarily for day-to-day dev.
# Build libraries from source, build docs (if any), and check dependencies.
build-all:
	raco setup --tidy $(DEPS-FLAGS) $(COLLECTION-NAME)

# Note: Each collection's info.rkt can say what to clean, for example
# (define clean '("compiled" "doc" "doc/<collect>")) to clean
# generated docs, too.
clean:
	raco setup --fast-clean $(COLLECTION-NAME)

# Primarily for use by CI, after make install -- since that already
# does the equivalent of make setup, this tries to do as little as
# possible except checking deps.
check-deps:
	raco setup --no-docs $(DEPS-FLAGS) $(COLLECTION-NAME)

# Suitable for both day-to-day dev and CI
test:
	raco test -x -p $(PACKAGE-NAME)

test-with-errortrace:
	racket -l errortrace -l racket -e '(require (submod "syntax/on.rkt" test))'

errortrace: test-with-errortrace

docs:
	raco docs $(COLLECTION-NAME)

coverage-check:
	raco cover -b -n dev -p $(PACKAGE-NAME)

coverage-report:
	open coverage/index.html

cover: coverage-check coverage-report

.PHONY:	help install remove build build-docs build-all clean check-deps test test-with-errortrace errortrace docs cover coverage-check coverage-report
