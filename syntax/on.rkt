#lang racket/base

(require syntax/parse/define
         racket/function
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
                   "more than one body form")
     (check-equal? (on (5)
                       [(eq? 5) 'five]
                       [else 'not-five])
                   'five
                   "eq?")
     (check-equal? (on (6)
                       [(eq? 5) 'five]
                       [else 'not-five])
                   'not-five
                   "eq?")
     (check-equal? (on ("hello")
                       [(equal? "hello") 'hello]
                       [else 'not-hello])
                   'hello
                   "equal?")
     (check-equal? (on ("bye")
                       [(equal? "hello") 'hello]
                       [else 'not-hello])
                   'not-hello
                   "equal?")
     (check-equal? (on (5)
                       [(and positive? integer?) 'yes]
                       [else 'no])
                   'yes
                   "and (conjoin)")
     (check-equal? (on (5.4)
                       [(and positive? integer?) 'yes]
                       [else 'no])
                   'no
                   "and (conjoin)")
     (check-equal? (on (5.3)
                       [(or positive? integer?) 'yes]
                       [else 'no])
                   'yes
                   "or (disjoin)")
     (check-equal? (on (-5.4)
                       [(or positive? integer?) 'yes]
                       [else 'no])
                   'no
                   "or (disjoin)")
     (check-equal? (on (-5)
                       [(not positive?) 'yes]
                       [else 'no])
                   'yes
                   "not (predicate negation)")
     (check-equal? (on (5)
                       [(not positive?) 'yes]
                       [else 'no])
                   'no
                   "not (predicate negation)")
     (check-equal? (on (5 "hi")
                       [(and-jux positive? string?) 'yes]
                       [else 'no])
                   'yes
                   "juxtaposed conjoin")
     (check-equal? (on (5 5)
                       [(and-jux positive? string?) 'yes]
                       [else 'no])
                   'no
                   "juxtaposed conjoin")
     (check-equal? (on (5 "hi")
                       [(or-jux positive? string?) 'yes]
                       [else 'no])
                   'yes
                   "juxtaposed disjoin")
     (check-equal? (on (-5 "hi")
                       [(or-jux positive? string?) 'yes]
                       [else 'no])
                   'yes
                   "juxtaposed disjoin")
     (check-equal? (on (-5 5)
                       [(or-jux positive? string?) 'yes]
                       [else 'no])
                   'no
                   "juxtaposed disjoin")
     (check-equal? (on (5)
                       [positive? (call add1)]
                       [else 'no])
                   6
                   "on-call")
     (check-equal? (on (-5)
                       [positive? (call add1)]
                       [else 'no])
                   'no
                   "on-call")
     (check-equal? (on (3 5)
                       [< (call +)]
                       [else 'no])
                   8
                   "on-call n-ary predicate")
     (check-equal? (on (3 5)
                       [> (call +)]
                       [else 'no])
                   'no
                   "on-call n-ary predicate")
     (check-equal? (on (-3 5)
                       [> (call +)]
                       [(or-jux positive? integer?) 'yes]
                       [else 'no])
                   'yes
                   "heterogeneous clauses")
     (check-equal? (on (-3 5)
                       [> (call +)]
                       [(and-jux positive? integer?) 'yes]
                       [else 'no])
                   'no
                   "heterogeneous clauses"))))

(module+ test
  (run-tests tests))
