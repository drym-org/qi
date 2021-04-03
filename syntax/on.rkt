#lang racket/base

(require syntax/parse/define
         racket/function
         mischief/shorthand
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
  [(_ ((~datum all) pred)) #'(give (curry andmap pred))]
  [(_ ((~datum any) pred)) #'(give (curry ormap pred))]
  [(_ ((~datum none) pred)) #'(negate (give (curry ormap pred)))]
  [(_ ((~datum and) pred ...)) #'(conjoin (on-predicate pred) ...)]
  [(_ ((~datum or) pred ...)) #'(disjoin (on-predicate pred) ...)]
  [(_ ((~datum not) pred)) #'(negate (on-predicate pred))]
  [(_ ((~datum and-jux) pred ...)) #'(conjux (on-predicate pred) ...)]
  [(_ ((~datum or-jux) pred ...)) #'(disjux (on-predicate pred) ...)]
  [(_ ((~datum with-key) f pred)) #'(compose
                                     (curry apply (on-predicate pred))
                                     (give (curry map f)))]
  [(_ pred) #'pred])

(define-syntax-parser on-consequent
  [(_ ((~datum call) func) arg ...) #'(func arg ...)]
  [(_ consequent arg ...) #'consequent])

(define-syntax-parser on
  [(_ (arg ...)) #'(cond)]
  [(_ (arg ...)
      ((~datum if) [predicate consequent ...] ...
                   [(~datum else) else-consequent ...]))
   #'(cond [((on-predicate predicate) arg ...)
            (on-consequent consequent arg ...) ...]
           ...
           [else (on-consequent else-consequent arg ...) ...])]
  [(_ (arg ...)
      ((~datum if) [predicate consequent ...] ...))
   #'(cond [((on-predicate predicate) arg ...)
            (on-consequent consequent arg ...) ...]
           ...)]
  [(_ (arg ...) predicate)
   #'((on-predicate predicate) arg ...)])

(define-syntax-parser switch
  [(_ (arg ...) expr ...)
   #'(on (arg ...)
         (if expr ...))])

(define-syntax-parser predicate-lambda
  [(_ (arg ...) expr ...)
   #'(lambda (arg ...)
       (on (arg ...)
           expr ...))])

(define-alias lambdap predicate-lambda)

(define-alias π predicate-lambda)

(define-syntax-parser define-predicate
  [(_ (name arg ...) expr ...)
   #'(define name
       (predicate-lambda (arg ...)
         expr ...))])

(define-syntax-parser switch-lambda
  [(_ (arg ...) expr ...)
   #'(lambda (arg ...)
       (switch (arg ...)
               expr ...))])

(define-syntax-parser define-switch
  [(_ (name arg ...) expr ...)
   #'(define name
       (switch-lambda (arg ...)
                      expr ...))])

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
       (check-equal? (switch (6 5)
                             [< 'yo])
                     (void)
                     "no matching clause")
       (check-equal? (switch (5)
                             [positive? 1 2 3])
                     3
                     "more than one body form"))
     (test-case
         "predicate-only"
       (check-true (on (5)
                       (and positive? (not even?))))
       (check-false (on (5)
                        (and positive? (not odd?))))
       (check-true (on ("5.0" "5")
                       (or eq?
                           equal?
                           (with-key string->number =))))
       (check-false (on ("5" "6")
                        (or eq?
                            equal?
                            (with-key string->number =)))))
     (test-case
         "unary predicate"
       (check-equal? (switch (5)
                             [negative? 'bye]
                             [positive? 'hi])
                     'hi)
       (check-equal? (switch (0)
                             [negative? 'bye]
                             [positive? 'hi]
                             [zero? 'later])
                     'later))
     (test-case
         "else"
       (check-equal? (switch (0)
                             [negative? 'bye]
                             [positive? 'hi]
                             [else 'later])
                     'later)
       (check-equal? (switch (0)
                             [else 'later])
                     'later)
       (check-equal? (switch (5 5)
                             [else 'yo])
                     'yo))
     (test-case
         "binary predicate"
       (check-equal? (switch (5 6)
                             [> 'bye]
                             [< 'hi]
                             [else 'yo])
                     'hi)
       (check-equal? (switch (5 5)
                             [> 'bye]
                             [< 'hi]
                             [else 'yo])
                     'yo))
     (test-case
         "n-ary predicate"
       (check-equal? (switch (5 5 6 7)
                             [> 'bye]
                             [< 'hi]
                             [else 'yo])
                     'yo)
       (check-equal? (switch (5 5 6 7)
                             [>= 'bye]
                             [<= 'hi]
                             [else 'yo])
                     'hi))
     (test-case
         "eq?"
       (check-equal? (switch (5)
                             [(eq? 5) 'five]
                             [else 'not-five])
                     'five)
       (check-equal? (switch (6)
                             [(eq? 5) 'five]
                             [else 'not-five])
                     'not-five))
     (test-case
         "equal?"
       (check-equal? (switch ("hello")
                             [(equal? "hello") 'hello]
                             [else 'not-hello])
                     'hello)
       (check-equal? (switch ("bye")
                             [(equal? "hello") 'hello]
                             [else 'not-hello])
                     'not-hello))
     (test-case
         "<"
       (check-equal? (switch (5)
                             [(< 10) 'yes]
                             [else 'no])
                     'yes)
       (check-equal? (switch (5)
                             [(< 1) 'yes]
                             [else 'no])
                     'no))
     (test-case
         ">"
       (check-equal? (switch (5)
                             [(> 1) 'yes]
                             [else 'no])
                     'yes)
       (check-equal? (switch (5)
                             [(> 10) 'yes]
                             [else 'no])
                     'no))
     (test-case
         "="
       (check-equal? (switch (5)
                             [(= 5) 'yes]
                             [else 'no])
                     'yes)
       (check-equal? (switch (5)
                             [(= 10) 'yes]
                             [else 'no])
                     'no))
     (test-case
         "predicate under a mapping"
       (check-equal? (switch ("5")
                             [(with-key string->number
                                (< 10)) 'yes]
                             [else 'no])
                     'yes)
       (check-equal? (switch ("5")
                             [(with-key string->number
                                (> 10)) 'yes]
                             [else 'no])
                     'no))
     (test-case
         "and (conjoin)"
       (check-equal? (switch (5)
                             [(and positive? integer?) 'yes]
                             [else 'no])
                     'yes)
       (check-equal? (switch (5.4)
                             [(and positive? integer?) 'yes]
                             [else 'no])
                     'no))
     (test-case
         "or (disjoin)"
       (check-equal? (switch (5.3)
                             [(or positive? integer?) 'yes]
                             [else 'no])
                     'yes)
       (check-equal? (switch (-5.4)
                             [(or positive? integer?) 'yes]
                             [else 'no])
                     'no)
       (check-equal? (switch (1 1)
                             [(or < >) 'a]
                             [else 'b])
                     'b)
       (check-equal? (switch ('a 'a)
                             [(or eq? equal?) 'a]
                             [else 'b])
                     'a)
       (check-equal? (switch ("abc" (symbol->string 'abc))
                             [(or eq? equal?) 'a]
                             [else 'b])
                     'a)
       (check-equal? (switch ('a 'b)
                             [(or eq? equal?) 'a]
                             [else 'b])
                     'b))
     (test-case
         "not (predicate negation)"
       (check-equal? (switch (-5)
                             [(not positive?) 'yes]
                             [else 'no])
                     'yes)
       (check-equal? (switch (5)
                             [(not positive?) 'yes]
                             [else 'no])
                     'no))
     (test-case
         "boolean combinators"
       (check-equal? (switch (5)
                             [(and positive?
                                   (or integer?
                                       odd?)) 'yes]
                             [else 'no])
                     'yes)
       (check-equal? (switch (5)
                             [(and positive?
                                   (or (> 6)
                                       even?)) 'yes]
                             [else 'no])
                     'no)
       (check-equal? (switch (5)
                             [(and positive?
                                   (or (eq? 3)
                                       (eq? 5))) 'yes]
                             [else 'no])
                     'yes)
       (check-equal? (switch (5)
                             [(and positive?
                                   (or (eq? 3)
                                       (eq? 6))) 'yes]
                             [else 'no])
                     'no))
     (test-case
         "juxtaposed boolean combinators"
       (check-equal? (switch (20 5)
                             [(and-jux positive?
                                       (or (> 10)
                                           odd?)) 'yes]
                             [else 'no])
                     'yes)
       (check-equal? (switch (20 5)
                             [(and-jux positive?
                                       (or (> 10)
                                           even?)) 'yes]
                             [else 'no])
                     'no))
     (test-case
         "juxtaposed conjoin"
       (check-equal? (switch (5 "hi")
                             [(and-jux positive? string?) 'yes]
                             [else 'no])
                     'yes)
       (check-equal? (switch (5 5)
                             [(and-jux positive? string?) 'yes]
                             [else 'no])
                     'no))
     (test-case
         "juxtaposed disjoin"
       (check-equal? (switch (5 "hi")
                             [(or-jux positive? string?) 'yes]
                             [else 'no])
                     'yes)
       (check-equal? (switch (-5 "hi")
                             [(or-jux positive? string?) 'yes]
                             [else 'no])
                     'yes)
       (check-equal? (switch (-5 5)
                             [(or-jux positive? string?) 'yes]
                             [else 'no])
                     'no))
     (test-case
         "on-call"
       (check-equal? (switch (5)
                             [positive? (call add1)]
                             [else 'no])
                     6)
       (check-equal? (switch (-5)
                             [positive? (call add1)]
                             [else 'no])
                     'no)
       (check-equal? (switch (3 5)
                             [< (call +)]
                             [else 'no])
                     8
                     "n-ary predicate")
       (check-equal? (switch (3 5)
                             [> (call +)]
                             [else 'no])
                     'no
                     "n-ary predicate"))
     (test-case
         "all"
       (check-equal? (switch (3 5)
                             [(all positive?) 'yes]
                             [else 'no])
                     'yes)
       (check-equal? (switch (3 -5)
                             [(all positive?) 'yes]
                             [else 'no])
                     'no))
     (test-case
         "any"
       (check-equal? (switch (3 5)
                             [(any positive?) 'yes]
                             [else 'no])
                     'yes)
       (check-equal? (switch (3 -5)
                             [(any positive?) 'yes]
                             [else 'no])
                     'yes)
       (check-equal? (switch (-3 -5)
                             [(any positive?) 'yes]
                             [else 'no])
                     'no))
     (test-case
         "none"
       (check-equal? (switch (-3 -5)
                             [(none positive?) 'yes]
                             [else 'no])
                     'yes)
       (check-equal? (switch (3 -5)
                             [(none positive?) 'yes]
                             [else 'no])
                     'no)
       (check-equal? (switch (3 5)
                             [(none positive?) 'yes]
                             [else 'no])
                     'no))
     (test-case
         "heterogeneous clauses"
       (check-equal? (switch (-3 5)
                             [> (call +)]
                             [(or-jux positive? integer?) 'yes]
                             [else 'no])
                     'yes)
       (check-equal? (switch (-3 5)
                             [> (call +)]
                             [(and-jux positive? integer?) 'yes]
                             [else 'no])
                     'no))
     (test-case
         "predicate lambda"
       (check-true ((predicate-lambda (x)
                                      (and positive? integer?))
                    5))
       (check-false ((predicate-lambda (x)
                                       (and positive? integer?))
                     -5))
       (check-false ((predicate-lambda (x)
                                       (and positive? integer?))
                     5.3))
       (check-true ((predicate-lambda (x y)
                                      (or < =))
                    5 6))
       (check-true ((predicate-lambda (x y)
                                      (or < =))
                    5 5))
       (check-false ((predicate-lambda (x y)
                                       (or < =))
                     5 4))
       (check-true ((π (x) (and (> 5) (< 10))) 7))
       (check-false ((π (x) (and (> 5) (< 10))) 2))
       (check-false ((π (x) (and (> 5) (< 10))) 12)))
     (test-case
         "switch lambda"
       (check-equal? ((switch-lambda (x)
                                     [(and positive? integer?) 'a])
                      5)
                     'a)
       (check-equal? ((switch-lambda (x)
                                     [(and positive? integer?) 'a]
                                     [else 'b])
                      -5)
                     'b)
       (check-equal? ((switch-lambda (x)
                                     [(and positive? integer?) 'a]
                                     [else 'b])
                      5.3)
                     'b)
       (check-equal? ((switch-lambda (x y)
                                     [(or < =) 'a])
                      5 6)
                     'a)
       (check-equal? ((switch-lambda (x y)
                                     [(or < =) 'a])
                      5 5)
                     'a)
       (check-equal? ((switch-lambda (x y)
                                     [(or < =) 'a]
                                     [else 'b])
                      5 4)
                     'b))
     (test-case
         "inline predicate"
       (check-true (on (6) (and (> 5) (< 10))))
       (check-false (on (4) (and (> 5) (< 10))))
       (check-false (on (14) (and (> 5) (< 10))))))))

(module+ test
  (run-tests tests))
