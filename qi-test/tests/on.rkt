#lang racket/base

(provide tests)

(require qi
         rackunit
         (only-in math sqr)
         racket/function)

(define tests
  (test-suite
   "on tests"
   (test-suite
    "Edge/base cases"
    (check-equal? (on (0))
                  (void)
                  "no clauses, unary")
    (check-equal? (on (5 5))
                  (void)
                  "no clauses, binary")
    (check-equal? (on ()
                    (const 3))
                  3
                  "no arguments"))
   (test-suite
    "smoke tests"
    (check-equal? (on (2) add1) 3)
    (check-equal? (on (2) (~> sqr add1)) 5)
    (check-equal? (on (2 3) (~> (>< sqr) +)) 13)
    (check-true (on (2) (eq? 2)))
    (check-true (on (2 -3) (and% positive? negative?)))
    (check-equal? (on (2) (if positive? add1 sub1)) 3))))
