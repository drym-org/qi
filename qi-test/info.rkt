#lang info

(define deps '())
(define build-deps '("rackunit-lib"
                     "cover"
                     "cover-coveralls"
                     "math-lib"
                     "relation"))
(define test-include-paths '("tests"))
(define test-omit-paths '("dev" "coverage"))
(define clean '("compiled" "private/compiled"))
