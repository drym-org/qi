#lang info

(define version "5.0")
(define collection "qi")
(define deps '("base"))
(define build-deps '("rackunit-lib"
                     "adjutor"
                     "math-lib"
                     "sandbox-lib"
                     "qi-lib"))
(define clean '("compiled" "tests/compiled" "tests/private/compiled"))
