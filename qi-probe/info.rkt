#lang info

(define version "2.0")
(define collection "qi")
(define deps '("base"
               "mischief"
               "qi-lib"))
(define build-deps '())
(define clean '("compiled" "private/compiled"))
(define compile-omit-paths '("tests"))
(define test-include-paths '("tests"))
(define pkg-authors '(countvajhula))
