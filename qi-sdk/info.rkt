#lang info

(define version "4.0")
(define collection "qi")
(define deps '("base"
               "qi-lib"
               "adjutor"
               "cli"
               "math-lib"
               "relation-lib"
               "csv-writing"
               "require-latency"
               ;; these are only used via `raco` in the Makefile,
               ;; and so they don't appear as dependencies of the
               ;; modules in this package but they are still needed
               "cover"
               "cover-coveralls"))
(define build-deps '("vlibench"
                     "scribble-lib"
                     "scribble-math"
                     "srfi-lite-lib"))
(define module-suffixes '(#"scrbl"))
(define clean '("compiled" "private/compiled"))
(define pkg-authors '(countvajhula))
