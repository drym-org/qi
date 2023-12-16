#lang info

(define version "3.0")
(define collection "qi")
(define deps '("base"))
(define build-deps '("rackunit-lib"
                     "adjutor"
                     "math-lib"
                     "qi-lib"
                     "syntax-spec-v1"))
(define clean '("compiled" "tests/compiled" "tests/private/compiled"))
