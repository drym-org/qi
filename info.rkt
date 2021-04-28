#lang info
(define collection 'multi)
(define deps '("base"
               "mischief"
               "fancy-app"))
(define build-deps '("scribble-lib"
                     "scribble-abbrevs"
                     "racket-doc"
                     "rackunit-lib"
                     "cover"
                     "cover-coveralls"
                     "sandbox-lib"
                     "math-lib"))
;; at the moment, this flag needs to be at the package level in order
;; for it to take effect, possibly because the tests are run against
;; the package rather than the collection
(define test-omit-paths '("dev" "coverage"))
;; TODO: these paths aren't getting cleaned
(define clean '("data/compiled" "data/private/compiled"))
(define pkg-desc "Predicate-based dispatch form.")
(define version "1.1")
(define pkg-authors '(countvajhula))
