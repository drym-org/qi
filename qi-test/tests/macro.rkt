#lang racket/base

(provide tests)

(require qi
         rackunit
         (only-in math sqr))

(define-qi-syntax-rule (square flo)
  (feedback 2 flo))

(define-qi-syntax-parser cube
  [(_ flo) (feedback 3 flo)])

(define tests
  (test-suite
   "macro tests"
   (check-equal? ((☯ (square sqr)) 2) 16)
   (check-equal? ((☯ (cube sqr)) 2) 256)))
