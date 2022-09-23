#lang info

(define version "3.0")
(define collection "qi")
(define deps '("base"))
(define build-deps '("cli"
                     "collections-lib"
                     "relation-lib"
                     "cover"
                     "cover-coveralls"))
(define clean '("compiled" "private/compiled"))
(define pkg-authors '(countvajhula))
