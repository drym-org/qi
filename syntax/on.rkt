#lang racket/base

(require syntax/parse/define
         racket/stxparam
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
         λ01
         <result>)

(module+ test
  (require rackunit
           rackunit/text-ui
           math))

(define-syntax-parser conjux-predicate
  [(_ (~datum _)) #'true.]
  [(_ pred:expr) #'(on-predicate pred)])

(define-syntax-parser disjux-predicate
  [(_ (~datum _)) #'false.]
  [(_ pred:expr) #'(on-predicate pred)])

(define-syntax-parser on-predicate
  [(_ ((~datum eq?) v:expr)) #'(curry eq? v)]
  [(_ ((~datum equal?) v:expr)) #'(curry equal? v)]
  [(_ ((~datum one-of?) v:expr ...)) #'(compose
                                        ->boolean
                                        (curryr member (list v ...)))]
  [(_ ((~datum =) v:expr)) #'(curry = v)]
  [(_ ((~datum <) v:expr)) #'(curryr < v)]
  [(_ ((~datum >) v:expr)) #'(curryr > v)]
  [(_ ((~or* (~datum <=) (~datum ≤)) v:expr)) #'(curryr <= v)]
  [(_ ((~or* (~datum >=) (~datum ≥)) v:expr)) #'(curryr >= v)]
  [(_ ((~datum all) pred:expr)) #'(give (curry andmap (on-predicate pred)))]
  [(_ ((~datum any) pred:expr)) #'(give (curry ormap (on-predicate pred)))]
  [(_ ((~datum none) pred:expr)) #'(on-predicate (not (any pred)))]
  [(_ ((~datum and) pred:expr ...)) #'(conjoin (on-predicate pred) ...)]
  [(_ ((~datum or) pred:expr ...)) #'(disjoin (on-predicate pred) ...)]
  [(_ ((~datum not) pred:expr)) #'(negate (on-predicate pred))]
  [(_ ((~datum and%) pred:expr ...)) #'(conjux (conjux-predicate pred) ...)]
  [(_ ((~datum or%) pred:expr ...)) #'(disjux (disjux-predicate pred) ...)]
  [(_ ((~datum with-key) f:expr pred:expr)) #'(compose
                                               (curry apply (on-predicate pred))
                                               (give (curry map f)))]
  [(_ ((~datum ..) func:expr ...)) #'(compose (on-predicate func) ...)]
  [(_ ((~datum %) func:expr)) #'(curry map-values (on-predicate func))]
  [(_ ((~datum apply) func:expr)) #'(curry apply (on-predicate func))]
  [(_ ((~datum map) func:expr)) #'(curry map (on-predicate func))]
  [(_ ((~datum filter) func:expr)) #'(curry filter (on-predicate func))]
  [(_ ((~datum foldl) func:expr init:expr)) #'(curry foldl (on-predicate func) init)]
  [(_ ((~datum foldr) func:expr init:expr)) #'(curry foldr (on-predicate func) init)]
  [(_ pred:expr) #'pred])

(define-syntax-parser on-consequent-call
  [(_ ((~datum ..) func:expr ...)) #'(compose (on-consequent-call func) ...)]
  [(_ ((~datum %) func:expr)) #'(curry map-values (on-consequent-call func))]
  [(_ ((~datum apply) func:expr)) #'(curry apply (on-consequent-call func))]
  [(_ ((~datum map) func:expr)) #'(curry map (on-consequent-call func))]
  [(_ ((~datum filter) func:expr)) #'(curry filter (on-consequent-call func))]
  [(_ ((~datum foldl) func:expr init:expr)) #'(curry foldl (on-consequent-call func) init)]
  [(_ ((~datum foldr) func:expr init:expr)) #'(curry foldr (on-consequent-call func) init)]
  [(_ func:expr) #'func])

(define-syntax-parser on-consequent
  [(_ ((~datum call) func:expr) arg:expr ...) #'((on-consequent-call func) arg ...)]
  [(_ consequent:expr arg:expr ...) #'consequent])

(define-syntax-parameter <result>
  (lambda (stx)
    (raise-syntax-error (syntax-e stx) "can only be used inside `on`")))

(define-syntax-parser on
  [(_ (arg:expr ...)) #'(cond)]
  [(_ (arg:expr ...)
      ((~datum if) [predicate consequent ...] ...
                   [(~datum else) else-consequent ...]))
   #'(cond [((on-predicate predicate) arg ...)
            =>
            (λ (x)
              (syntax-parameterize ([<result> (make-rename-transformer #'x)])
                (on-consequent consequent arg ...)
                ...))]
           ...
           [else (on-consequent else-consequent arg ...) ...])]
  [(_ (arg:expr ...)
      ((~datum if) [predicate consequent ...] ...))
   #'(cond [((on-predicate predicate) arg ...)
            =>
            (λ (x)
              (syntax-parameterize ([<result> (make-rename-transformer #'x)])
                (on-consequent consequent arg ...)
                ...))]
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
                             [(< 5) 'yes]
                             [else 'no])
                     'no))
     (test-case
         "<="
       (check-equal? (switch (5)
                             [(<= 10) 'yes]
                             [else 'no])
                     'yes)
       (check-equal? (switch (5)
                             [(<= 5) 'yes]
                             [else 'no])
                     'yes)
       (check-equal? (switch (5)
                             [(<= 1) 'yes]
                             [else 'no])
                     'no))
     (test-case
         ">"
       (check-equal? (switch (5)
                             [(> 1) 'yes]
                             [else 'no])
                     'yes)
       (check-equal? (switch (5)
                             [(> 5) 'yes]
                             [else 'no])
                     'no))
     (test-case
         ">="
       (check-equal? (switch (5)
                             [(>= 1) 'yes]
                             [else 'no])
                     'yes)
       (check-equal? (switch (5)
                             [(>= 5) 'yes]
                             [else 'no])
                     'yes)
       (check-equal? (switch (5)
                             [(>= 10) 'yes]
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
         "map"
       (check-equal? (on ((list 1 2 3))
                         (map add1))
                     (list 2 3 4)
                     "map in predicate")
       (check-equal? (switch ((list 3 2 1))
                             [(apply >) (call (map add1))]
                             [else 'no])
                     (list 4 3 2)
                     "map in consequent"))
     (test-case
         "filter"
       (check-equal? (on ((list 1 2 3))
                         (filter odd?))
                     (list 1 3)
                     "filter in predicate")
       (check-equal? (switch ((list 3 2 1))
                             [(apply >) (call (filter even?))]
                             [else 'no])
                     (list 2)
                     "filter in consequent"))
     (test-case
         "foldl"
       (check-equal? (on ((list "a" "b" "c"))
                         (foldl string-append ""))
                     "cba"
                     "foldl in predicate")
       (check-equal? (switch ((list 3 2 1))
                             [(apply >) (call (foldl + 1))]
                             [else 'no])
                     7
                     "foldl in consequent"))
     (test-case
         "foldr"
       (check-equal? (on ((list "a" "b" "c"))
                         (foldr string-append ""))
                     "abc"
                     "foldr in predicate")
       (check-equal? (switch ((list 3 2 1))
                             [(apply >) (call (foldr + 1))]
                             [else 'no])
                     7
                     "foldr in consequent"))
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
       (check-false (on (14) (and (> 5) (< 10)))))
     (test-case
         "result of predicate expression"
       (check-equal? (switch (6)
                             [add1 (add1 <result>)]
                             [else 'hi])
                     8)
       (check-equal? (switch (2)
                             [(curryr member (list 1 5 4 2 6)) <result>]
                             [else 'hi])
                     (list 2 6))
       (check-equal? (switch (2)
                             [(curryr member (list 1 5 4 2 6)) (length <result>)]
                             [else 'hi])
                     2)
       (check-equal? (switch ((list add1 sub1))
                             [(curry car) (<result> 5)]
                             [else 'hi])
                     6)
       (check-equal? (switch (2 3)
                             [+ <result>]
                             [else 'hi])
                     5)))))

(module+ test
  (run-tests tests))
