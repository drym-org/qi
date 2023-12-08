#lang racket/base

(provide tests)

(require qi/flow/core/util
         rackunit
         rackunit/text-ui
         (only-in racket/function
                  curryr))

(define tests
  (test-suite
   "Compiler utilities tests"

   (test-suite
    "fixed point"
    (check-equal? ((fix abs) -1) 1)
    (check-equal? ((fix abs) -1) 1)
    (let ([integer-div2 (compose floor (curryr / 2))])
      (check-equal? ((fix integer-div2) 10)
                    0)))))

(module+ main
  (void (run-tests tests)))
