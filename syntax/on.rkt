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
  [(_ ((~datum eq?) v)) #'(curry eq? v)]
  [(_ ((~datum equal?) v)) #'(curry equal? v)]
  [(_ ((~datum =) v)) #'(curry = v)]
  [(_ ((~datum <) v)) #'(curryr < v)]
  [(_ ((~datum >) v)) #'(curryr > v)]
  [(_ ((~datum all) pred)) #'(curry give (curry andmap pred))]
  [(_ ((~datum any) pred)) #'(curry give (curry ormap pred))]
  [(_ ((~datum none) pred)) #'(negate (curry give (curry ormap pred)))]
  [(_ ((~datum and) preds ...)) #'(conjoin preds ...)]
  [(_ ((~datum or) preds ...)) #'(disjoin preds ...)]
  [(_ ((~datum not) pred)) #'(negate pred)]
  [(_ ((~datum and-jux) preds ...)) #'(conjux preds ...)]
  [(_ ((~datum or-jux) preds ...)) #'(disjux preds ...)]
  [(_ pred) #'pred])

(define-syntax-parser on-consequent
  [(_ ((~datum call) func) arg ...) #'(func arg ...)]
  [(_ consequent arg ...) #'consequent])

(define-syntax-parser on
  [(_ (arg ...)) #'(cond)]
  [(_ (arg ...)
      [predicate consequent ...] ...
      [(~datum else) else-consequent ...])
   #'(cond [((on-predicate predicate) arg ...)
            (on-consequent consequent arg ...) ...]
           ...
           [else (on-consequent else-consequent arg ...) ...])]
  [(_ (arg ...)
      [predicate consequent ...] ...)
   #'(cond [((on-predicate predicate) arg ...)
            (on-consequent consequent arg ...) ...]
           ...)])

(module+ test

  (define tests
    (test-suite
     "On tests"
     (test-case
         "Edge/base cases"
       (check-equal? (on (0))
                     (void)
                     "no clauses, unary")
       (check-equal? (on (5 5))
                     (void)
                     "no clauses, binary")
       (check-equal? (on (6 5)
                         [< 'yo])
                     (void)
                     "no matching clause")
       (check-equal? (on (5)
                         [positive? 1 2 3])
                     3
                     "more than one body form"))
     (test-case
         "unary predicate"
       (check-equal? (on (5)
                         [negative? 'bye]
                         [positive? 'hi])
                     'hi)
       (check-equal? (on (0)
                         [negative? 'bye]
                         [positive? 'hi]
                         [zero? 'later])
                     'later))
     (test-case
         "else"
       (check-equal? (on (0)
                         [negative? 'bye]
                         [positive? 'hi]
                         [else 'later])
                     'later)
       (check-equal? (on (0)
                         [else 'later])
                     'later)
       (check-equal? (on (5 5)
                         [else 'yo])
                     'yo))
     (test-case
         "binary predicate"
       (check-equal? (on (5 6)
                         [> 'bye]
                         [< 'hi]
                         [else 'yo])
                     'hi)
       (check-equal? (on (5 5)
                         [> 'bye]
                         [< 'hi]
                         [else 'yo])
                     'yo))
     (test-case
         "n-ary predicate"
       (check-equal? (on (5 5 6 7)
                         [> 'bye]
                         [< 'hi]
                         [else 'yo])
                     'yo)
       (check-equal? (on (5 5 6 7)
                         [>= 'bye]
                         [<= 'hi]
                         [else 'yo])
                     'hi))
     (test-case
         "eq?"
       (check-equal? (on (5)
                         [(eq? 5) 'five]
                         [else 'not-five])
                     'five)
       (check-equal? (on (6)
                         [(eq? 5) 'five]
                         [else 'not-five])
                     'not-five))
     (test-case
         "equal?"
       (check-equal? (on ("hello")
                         [(equal? "hello") 'hello]
                         [else 'not-hello])
                     'hello)
       (check-equal? (on ("bye")
                         [(equal? "hello") 'hello]
                         [else 'not-hello])
                     'not-hello))
     (test-case
         "<"
       (check-equal? (on (5)
                         [(< 10) 'yes]
                         [else 'no])
                     'yes)
       (check-equal? (on (5)
                         [(< 1) 'yes]
                         [else 'no])
                     'no))
     (test-case
         ">"
       (check-equal? (on (5)
                         [(> 1) 'yes]
                         [else 'no])
                     'yes)
       (check-equal? (on (5)
                         [(> 10) 'yes]
                         [else 'no])
                     'no))
     (test-case
         "="
       (check-equal? (on (5)
                         [(= 5) 'yes]
                         [else 'no])
                     'yes)
       (check-equal? (on (5)
                         [(= 10) 'yes]
                         [else 'no])
                     'no))
     (test-case
         "and (conjoin)"
       (check-equal? (on (5)
                         [(and positive? integer?) 'yes]
                         [else 'no])
                     'yes)
       (check-equal? (on (5.4)
                         [(and positive? integer?) 'yes]
                         [else 'no])
                     'no))
     (test-case
         "or (disjoin)"
       (check-equal? (on (5.3)
                         [(or positive? integer?) 'yes]
                         [else 'no])
                     'yes)
       (check-equal? (on (-5.4)
                         [(or positive? integer?) 'yes]
                         [else 'no])
                     'no)
       (check-equal? (on (1 1)
                         [(or < >) 'a]
                         [else 'b])
                     'b)
       (check-equal? (on ('a 'a)
                         [(or eq? equal?) 'a]
                         [else 'b])
                     'a)
       (check-equal? (on ("abc" (symbol->string 'abc))
                         [(or eq? equal?) 'a]
                         [else 'b])
                     'a)
       (check-equal? (on ('a 'b)
                         [(or eq? equal?) 'a]
                         [else 'b])
                     'b))
     (test-case
         "not (predicate negation)"
       (check-equal? (on (-5)
                         [(not positive?) 'yes]
                         [else 'no])
                     'yes)
       (check-equal? (on (5)
                         [(not positive?) 'yes]
                         [else 'no])
                     'no))
     (test-case
         "juxtaposed conjoin"
       (check-equal? (on (5 "hi")
                         [(and-jux positive? string?) 'yes]
                         [else 'no])
                     'yes)
       (check-equal? (on (5 5)
                         [(and-jux positive? string?) 'yes]
                         [else 'no])
                     'no))
     (test-case
         "juxtaposed disjoin"
       (check-equal? (on (5 "hi")
                         [(or-jux positive? string?) 'yes]
                         [else 'no])
                     'yes)
       (check-equal? (on (-5 "hi")
                         [(or-jux positive? string?) 'yes]
                         [else 'no])
                     'yes)
       (check-equal? (on (-5 5)
                         [(or-jux positive? string?) 'yes]
                         [else 'no])
                     'no))
     (test-case
         "on-call"
       (check-equal? (on (5)
                         [positive? (call add1)]
                         [else 'no])
                     6)
       (check-equal? (on (-5)
                         [positive? (call add1)]
                         [else 'no])
                     'no)
       (check-equal? (on (3 5)
                         [< (call +)]
                         [else 'no])
                     8
                     "n-ary predicate")
       (check-equal? (on (3 5)
                         [> (call +)]
                         [else 'no])
                     'no
                     "n-ary predicate"))
     (test-case
         "all"
       (check-equal? (on (3 5)
                         [(all positive?) 'yes]
                         [else 'no])
                     'yes)
       (check-equal? (on (3 -5)
                         [(all positive?) 'yes]
                         [else 'no])
                     'no))
     (test-case
         "any"
       (check-equal? (on (3 5)
                         [(any positive?) 'yes]
                         [else 'no])
                     'yes)
       (check-equal? (on (3 -5)
                         [(any positive?) 'yes]
                         [else 'no])
                     'yes)
       (check-equal? (on (-3 -5)
                         [(any positive?) 'yes]
                         [else 'no])
                     'no))
     (test-case
         "none"
       (check-equal? (on (-3 -5)
                         [(none positive?) 'yes]
                         [else 'no])
                     'yes)
       (check-equal? (on (3 -5)
                         [(none positive?) 'yes]
                         [else 'no])
                     'no)
       (check-equal? (on (3 5)
                         [(none positive?) 'yes]
                         [else 'no])
                     'no))
     (test-case
         "heterogeneous clauses"
       (check-equal? (on (-3 5)
                         [> (call +)]
                         [(or-jux positive? integer?) 'yes]
                         [else 'no])
                     'yes)
       (check-equal? (on (-3 5)
                         [> (call +)]
                         [(and-jux positive? integer?) 'yes]
                         [else 'no])
                     'no)))))

(module+ test
  (run-tests tests))
