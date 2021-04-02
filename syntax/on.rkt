#lang racket/base

(require syntax/parse/define
         (for-syntax racket/base))

(provide on)

(module+ test
  (require rackunit
           rackunit/text-ui))

(define-syntax-parser on
  [(on (arg ...)) #'(cond)]
  [(on (arg ...)
       [predicate consequent ...] ...
       [(~datum else) else-consequent ...])
   #'(cond [(predicate arg ...) consequent ...]
           ...
           [else else-consequent ...])]
  [(on (arg ...)
       [predicate consequent ...] ...)
   #'(cond [(predicate arg ...) consequent ...]
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
