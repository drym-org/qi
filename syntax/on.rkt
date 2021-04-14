#lang racket/base

(require syntax/parse/define
         racket/function
         mischief/shorthand
         (for-syntax racket/base))

(require "private/util.rkt")

(provide on
         switch
         switch-lambda
         define-switch
         lambda/subject
         define/subject
         predicate-lambda
         define-predicate
         lambdap
         π
         λ01)

(module+ test
  (require rackunit
           rackunit/text-ui
           math))

(define-syntax-parser conjux-predicate
  [(_ (~datum _)) #'true.]
  [(_ pred) #'(on-predicate pred)])

(define-syntax-parser disjux-predicate
  [(_ (~datum _)) #'false.]
  [(_ pred) #'(on-predicate pred)])

(define-syntax-parser on-predicate
  [(_ ((~datum eq?) v)) #'(curry eq? v)]
  [(_ ((~datum equal?) v)) #'(curry equal? v)]
  [(_ ((~datum one-of?) v ...)) #'(compose
                                   ->boolean
                                   (curryr member (list v ...)))]
  [(_ ((~datum =) v)) #'(curry = v)]
  [(_ ((~datum <) v)) #'(curryr < v)]
  [(_ ((~datum >) v)) #'(curryr > v)]
  [(_ ((~datum all) pred)) #'(give (curry andmap (on-predicate pred)))]
  [(_ ((~datum any) pred)) #'(give (curry ormap (on-predicate pred)))]
  [(_ ((~datum none) pred)) #'(on-predicate (not (any pred)))]
  [(_ ((~datum and) pred ...)) #'(conjoin (on-predicate pred) ...)]
  [(_ ((~datum or) pred ...)) #'(disjoin (on-predicate pred) ...)]
  [(_ ((~datum not) pred)) #'(negate (on-predicate pred))]
  [(_ ((~datum and%) pred ...)) #'(conjux (conjux-predicate pred) ...)]
  [(_ ((~datum or%) pred ...)) #'(disjux (disjux-predicate pred) ...)]
  [(_ ((~datum with-key) f pred)) #'(compose
                                     (curry apply (on-predicate pred))
                                     (give (curry map f)))]
  [(_ ((~datum ..) func ...)) #'(compose (on-predicate func) ...)]
  [(_ ((~datum %) func)) #'(curry map-values (on-predicate func))]
  [(_ ((~datum apply) func)) #'(curry apply (on-predicate func))]
  [(_ pred) #'pred])

(define-syntax-parser on-consequent-call
  [(_ ((~datum ..) func ...)) #'(compose (on-consequent-call func) ...)]
  [(_ ((~datum %) func)) #'(curry map-values (on-consequent-call func))]
  [(_ ((~datum apply) func)) #'(curry apply (on-consequent-call func))]
  [(_ func) #'func])

(define-syntax-parser on-consequent
  [(_ ((~datum call) func) arg ...) #'((on-consequent-call func) arg ...)]
  [(_ consequent arg ...) #'consequent])

(define-syntax-parser on
  [(_ (arg:expr ...)) #'(cond)]
  [(_ (arg:expr ...)
      ((~datum if) [predicate consequent ...] ...
                   [(~datum else) else-consequent ...]))
   #'(cond [((on-predicate predicate) arg ...)
            (on-consequent consequent arg ...) ...]
           ...
           [else (on-consequent else-consequent arg ...) ...])]
  [(_ (arg:expr ...)
      ((~datum if) [predicate consequent ...] ...))
   #'(cond [((on-predicate predicate) arg ...)
            (on-consequent consequent arg ...) ...]
           ...)]
  [(_ (arg:expr ...) predicate)
   #'((on-predicate predicate) arg ...)])

(define-syntax-parser switch
  [(_ (arg:expr ...) expr:expr ...)
   #'(on (arg ...)
         (if expr ...))])

(define-syntax-parser lambda/subject
  [(_ (arg:id ...) expr:expr ...)
   #'(lambda (arg ...)
       (on (arg ...)
           expr ...))]
  [(_ rest-args:id expr:expr ...)
   #'(lambda rest-args
       (on (rest-args)
           expr ...))])

(define-alias predicate-lambda lambda/subject)

(define-alias lambdap predicate-lambda)

(define-alias π predicate-lambda)

(define-syntax-parser define/subject
  [(_ (name:id arg:id ...) expr:expr ...)
   #'(define name
       (lambda/subject (arg ...)
         expr ...))])

(define-alias define-predicate define/subject)

(define-syntax-parser switch-lambda
  [(_ (arg:id ...) expr:expr ...)
   #'(lambda (arg ...)
       (switch (arg ...)
               expr ...))]
  [(_ rest-args:id expr:expr ...)
   #'(lambda rest-args
       (switch (rest-args)
               expr ...))])

(define-alias λ01 switch-lambda)

(define-syntax-parser define-switch
  [(_ (name:id arg:id ...) expr:expr ...)
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
                     "more than one body form")
       (check-equal? (on ()
                         (const 3))
                     3
                     "no arguments"))
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
       (check-true (on ("5.0" "5")
                       (or eq?
                           equal?
                           (.. = (% string->number)))))
       (check-false (on ("5" "6")
                        (or eq?
                            equal?
                            (with-key string->number =))))
       (check-false (on ("5" "6")
                        (or eq?
                            equal?
                            (.. = (% string->number))))))
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
         "one-of?"
       (check-equal? (switch ("hello")
                             [(one-of? "hi" "hello") 'yes]
                             [else 'no])
                     'yes)
       (check-equal? (switch ("hello")
                             [(one-of? "hi" "ola") 'yes]
                             [else 'no])
                     'no))
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
                             [(and% positive?
                                    (or (> 10)
                                        odd?)) 'yes]
                             [else 'no])
                     'yes)
       (check-equal? (switch (20 5)
                             [(and% positive?
                                    (or (> 10)
                                        even?)) 'yes]
                             [else 'no])
                     'no))
     (test-case
         "juxtaposed conjoin"
       (check-equal? (switch (5 "hi")
                             [(and% positive? string?) 'yes]
                             [else 'no])
                     'yes)
       (check-equal? (switch (5 5)
                             [(and% positive? string?) 'yes]
                             [else 'no])
                     'no)
       (check-equal? (switch (5 "hi")
                             [(and% positive? _) 'yes]
                             [else 'no])
                     'yes)
       (check-equal? (switch (5 "hi")
                             [(and% _ string?) 'yes]
                             [else 'no])
                     'yes))
     (test-case
         "juxtaposed disjoin"
       (check-equal? (switch (5 "hi")
                             [(or% positive? string?) 'yes]
                             [else 'no])
                     'yes)
       (check-equal? (switch (-5 "hi")
                             [(or% positive? string?) 'yes]
                             [else 'no])
                     'yes)
       (check-equal? (switch (-5 5)
                             [(or% positive? string?) 'yes]
                             [else 'no])
                     'no)
       (check-equal? (switch (-5 "hi")
                             [(or% positive? _) 'yes]
                             [else 'no])
                     'no)
       (check-equal? (switch (5 "hi")
                             [(or% positive? _) 'yes]
                             [else 'no])
                     'yes)
       (check-equal? (switch (5 "hi")
                             [(or% _ string?) 'yes]
                             [else 'no])
                     'yes)
       (check-equal? (switch (5 5)
                             [(or% _ string?) 'yes]
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
                     "n-ary predicate")
       (check-equal? (switch (3 5)
                             [< (call (.. + (% add1)))]
                             [else 'no])
                     10
                     ".. and % in call position")
       (check-equal? (switch (3 5)
                             [< (call (.. + (% (.. add1 sqr))))]
                             [else 'no])
                     36
                     ".. and % in call position"))
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
         "apply"
       (check-equal? (switch ((list 1 2 3))
                             [(apply >) 'yes]
                             [else 'no])
                     'no
                     "apply in predicate")
       (check-equal? (switch ((list 3 2 1))
                             [(apply >) 'yes]
                             [else 'no])
                     'yes
                     "apply in predicate")
       (check-equal? (switch ((list 3 2 1))
                             [(apply >) (call (apply +))]
                             [else 'no])
                     6
                     "apply in consequent"))
     (test-case
         "heterogeneous clauses"
       (check-equal? (switch (-3 5)
                             [> (call +)]
                             [(or% positive? integer?) 'yes]
                             [else 'no])
                     'yes)
       (check-equal? (switch (-3 5)
                             [> (call +)]
                             [(and% positive? integer?) 'yes]
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
       (check-false ((π (x) (and (> 5) (< 10))) 12))
       (check-true ((π args list?) 1 2 3) "packed args")
       (check-false ((π args (.. (> 3) length)) 1 2 3) "packed args")
       (check-true ((π args (.. (> 3) length)) 1 2 3 4) "packed args")
       (check-false ((π args (apply >)) 1 2 3) "apply with packed args")
       (check-true ((π args (apply >)) 3 2 1) "apply with packed args"))
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
                     'b)
       (check-equal? ((λ01 args [list? 'a]) 1 2 3) 'a)
       (check-equal? ((λ01 args
                           [(.. (> 3) length) 'a]
                           [else 'b]) 1 2 3)
                     'b
                     "packed args")
       (check-equal? ((λ01 args
                           [(.. (> 3) length) 'a]
                           [else 'b]) 1 2 3 4)
                     'a
                     "packed args")
       (check-equal? ((λ01 args
                           [(apply <) 'a]
                           [else 'b]) 1 2 3)
                     'a
                     "apply with packed args")
       (check-equal? ((λ01 args
                           [(apply <) 'a]
                           [else 'b]) 1 3 2)
                     'b
                     "apply with packed args"))
     (test-case
         "inline predicate"
       (check-true (on (6) (and (> 5) (< 10))))
       (check-false (on (4) (and (> 5) (< 10))))
       (check-false (on (14) (and (> 5) (< 10))))))))

(module+ test
  (run-tests tests))
