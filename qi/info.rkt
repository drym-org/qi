#lang info

(define version "3.0")
(define collection 'multi)
(define deps '("base"
               "qi-lib"
               "qi-doc"
               "qi-test"
               "qi-probe"
               "Qi-Quickscripts"))
(define build-deps '("cli"
                     "collections-lib"))
(define implies '("qi-lib"
                  "qi-doc"
                  "qi-test"
                  "qi-probe"
                  "Qi-Quickscripts"))
