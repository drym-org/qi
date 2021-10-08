#lang info
(define collection "qi")
(define deps '("base"
               "mischief"
               "fancy-app"
               "typed-stack"
               "adjutor"))
(define build-deps '("scribble-lib"
                     "scribble-abbrevs"
                     "racket-doc"
                     "rackunit-lib"
                     "cover"
                     "cover-coveralls"
                     "sandbox-lib"
                     "math-lib"
                     "relation"))
(define scribblings '(("scribblings/qi.scrbl" ())))
(define compile-omit-paths '("dev" "tests" "coverage"))
(define test-include-paths '("tests"))
(define test-omit-paths '("dev" "coverage"))
(define clean '("compiled" "doc" "doc/qi" "private/compiled"))
(define pkg-desc "Predicate-based dispatch form.")
(define version "0.0")
(define pkg-authors '(countvajhula))
