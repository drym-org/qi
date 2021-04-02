#lang racket/base

(require syntax/parse/define
         (for-syntax racket/base))

(require "private/util.rkt")

(provide on)

(module+ test
  (require rackunit
           rackunit/text-ui))

(define-syntax-parser on-predicate
  [(on-predicate ((~datum eq?) v)) #'(curry eq? v)]
  [(on-predicate ((~datum equal?) v)) #'(curry equal? v)]
  [(on-predicate ((~datum and) preds ...)) #'(conjoin preds ...)]
  [(on-predicate ((~datum or) preds ...)) #'(disjoin preds ...)]
  [(on-predicate ((~datum not) pred)) #'(negate pred)]
  [(on-predicate ((~datum and-jux) preds ...)) #'(conjux preds ...)]
  [(on-predicate ((~datum or-jux) preds ...)) #'(disjux preds ...)]
  [(on-predicate fn) #'fn])

(define-syntax-parser on-consequent
  [(on-consequent ((~datum call) func) arg ...)
   #'(func arg ...)]
  [(on-consequent consequent arg ...)
   #'consequent])

(define-syntax-parser on
  [(on (arg ...)) #'(cond)]
  [(on (arg ...)
       [predicate consequent ...] ...
       [(~datum else) else-consequent ...])
   #'(cond [((on-predicate predicate) arg ...)
            (on-consequent consequent arg ...) ...]
           ...
           [else (on-consequent else-consequent arg ...) ...])]
  [(on (arg ...)
       [predicate consequent ...] ...)
   #'(cond [((on-predicate predicate) arg ...)
            (on-consequent consequent arg ...) ...]
           ...)])

(module+ test

  (define tests
    (test-suite
     "On tests"
     (check-equal? (on (5)
                       [negative? 'bye]
                       [positive? 'hi])
                   'hi)
     (check-equal? (on (0)
                       [negative? 'bye]
                       [positive? 'hi]
                       [zero? 'later])
                   'later)
     (check-equal? (on (0)
                       [negative? 'bye]
                       [positive? 'hi]
                       [else 'later])
                   'later)
     (check-equal? (on (0)
                       [else 'later])
                   'later)
     (check-equal? (on (0)) (void))
     (check-equal? (on (5 6)
                       [> 'bye]
                       [< 'hi]
                       [else 'yo])
                   'hi)
     (check-equal? (on (5 5)
                       [> 'bye]
                       [< 'hi]
                       [else 'yo])
                   'yo)
     (check-equal? (on (5 5 6 7)
                       [> 'bye]
                       [< 'hi]
                       [else 'yo])
                   'yo)
     (check-equal? (on (5 5 6 7)
                       [>= 'bye]
                       [<= 'hi]
                       [else 'yo])
                   'hi)
     (check-equal? (on (6 5)
                       [< 'yo])
                   (void))
     (check-equal? (on (5 5)
                       [else 'yo])
                   'yo)
     (check-equal? (on (5 5))
                   (void))
     (check-equal? (on (5)
                       [positive? 1 2 3])
                   3
                   "more than one body form"))))

(module+ test
  (run-tests tests))
