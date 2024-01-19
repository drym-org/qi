#lang info

(define version "4.0")
(define collection "qi")
(define deps '("base"
               "qi-lib"
               "adjutor"
               "cli"
               "math-lib"
               "collections-lib"
               "relation-lib"
               "csv-writing"
               "require-latency"
               "git://gitlab.com/racketeer/qi-benchmarks.git#master"
               "cover"
               "cover-coveralls"))
(define build-deps '())
(define clean '("compiled" "private/compiled"))
(define pkg-authors '(countvajhula))
