#lang racket/base

(require qi
         rackunit
         rackunit/text-ui
         (only-in math sqr)
         (only-in adjutor values->list)
         racket/list
         racket/string
         racket/function
         "private/util.rkt")

;; used in the "language extension" tests for `qi:*`
(define tests
  (test-suite
   "flow tests"

   (check-equal? #t #t)
   ;; (check-equal? ((flow-dummy (~>> add1)) 5) 6)
   ))

(module+ main
  (void (run-tests tests)))
