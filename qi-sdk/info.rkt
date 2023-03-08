#lang info

(define version "3.0")
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
               "cover"
               "cover-coveralls"))
(define build-deps '())
(define clean '("compiled" "private/compiled"))
(define pkg-authors '(countvajhula))
