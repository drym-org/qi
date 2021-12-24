#lang info

(define version "0.0")
(define collection "qi")
(define deps '("base"
               "mischief"
               "version-case"
               "qi-lib"))
(define build-deps '())
(define clean '("compiled" "private/compiled"))
(define compile-omit-paths '("tests"))
(define test-include-paths '("tests"))
(define pkg-authors '(countvajhula))
