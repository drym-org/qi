#lang info

(define version "1.0")
(define collection 'multi)
(define deps '("base"
               "qi-lib"
               "qi-doc"
               "qi-test"
               "qi-probe"))
(define build-deps '())
(define implies '("qi-lib"
                  "qi-doc"
                  "qi-test"
                  "qi-probe"))
