#lang racket/base

(require syntax/parse/define
         syntax/parse
         fancy-app
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
           (only-in math sqr)
           racket/list))

(begin-for-syntax
  (require (only-in racket/function identity))

  (define (repeat n v)
    (if (= 0 n)
        null
        (cons v (repeat (sub1 n) v)))))

(define-syntax-parser conjux-clause
  [(_ (~datum _)) #'true.]
  [(_ onex:expr) #'(on-clause onex)])

(define-syntax-parser disjux-clause
  [(_ (~datum _)) #'false.]
  [(_ onex:expr) #'(on-clause onex)])

;; "prarg" = "pre-supplied argument"

(define-syntax-parser on-clause
  [(_ ((~datum one-of?) v:expr ...)) #'(compose
                                        ->boolean
                                        (curryr member (list v ...)))]
  [(_ ((~datum all) onex:expr)) #'(give (curry andmap (on-clause onex)))]
  [(_ ((~datum any) onex:expr)) #'(give (curry ormap (on-clause onex)))]
  [(_ ((~datum none) onex:expr)) #'(on-clause (not (any onex)))]
  [(_ ((~datum and) onex:expr ...)) #'(conjoin (on-clause onex) ...)]
  [(_ ((~datum or) onex:expr ...)) #'(disjoin (on-clause onex) ...)]
  [(_ ((~datum not) onex:expr)) #'(negate (on-clause onex))]
  [(_ ((~datum and%) onex:expr ...)) #'(conjux (conjux-clause onex) ...)]
  [(_ ((~datum or%) onex:expr ...)) #'(disjux (disjux-clause onex) ...)]
  [(_ ((~datum with-key) f:expr onex:expr)) #'(compose
                                               (curry apply (on-clause onex))
                                               (give (curry map (on-clause f))))]
  [(_ ((~datum ..) func:expr ...)) #'(compose (on-clause func) ...)]
  [(_ ((~datum compose) func:expr ...)) #'(compose (on-clause func) ...)]
  [(_ ((~datum ~>) func:expr ...)) #'(rcompose (on-clause func) ...)]
  [(_ ((~datum thread) func:expr ...)) #'(rcompose (on-clause func) ...)]
  [(_ ((~datum ><) func:expr)) #'(curry map-values (on-clause func))]
  [(_ ((~datum amp) func:expr)) #'(curry map-values (on-clause func))]
  [(_ ((~datum ==) func:expr ...)) #'(relay (on-clause func) ...)]
  [(_ ((~datum relay) func:expr ...)) #'(relay (on-clause func) ...)]
  [(_ ((~datum -<) func:expr ...)) #'(λ args (values (apply (on-clause func) args) ...))]
  [(_ ((~datum tee) func:expr ...)) #'(λ args (values (apply (on-clause func) args) ...))]
  [(_ ((~datum splitter) n:number))
   (datum->syntax this-syntax
                  (cons 'on-clause
                        (list (cons '-<
                                    (repeat (syntax->datum #'n)
                                            identity)))))]
  [(_ (onex prarg-pre ... (~datum _) prarg-post ...))
   #'((on-clause onex) prarg-pre ... _ prarg-post ...)]
  [(_ (onex prarg ...))
   #'(curryr (on-clause onex) prarg ...)]
  [(_ onex:expr) #'onex])

(define-syntax-parser switch-consequent
  [(_ ((~datum call) func:expr) arg:expr ...) #'((on-clause func) arg ...)]
  [(_ consequent:expr arg:expr ...) #'consequent])

(define-syntax-parameter <result>
  (lambda (stx)
    (raise-syntax-error (syntax-e stx) "can only be used inside `on`")))

(define-syntax-parser on
  [(_ (arg:expr ...)) #'(void)]
  [(_ (arg:expr ...) clause)
   #'((on-clause clause) arg ...)])

(define-syntax-parser switch
  [(_ (arg:expr ...)
      [predicate consequent ...]
      ...
      [(~datum else) else-consequent ...])
   #'(cond [((on-clause predicate) arg ...)
            =>
            (λ (x)
              (syntax-parameterize ([<result> (make-rename-transformer #'x)])
                (switch-consequent consequent arg ...)
                ...))]
           ...
           [else (switch-consequent else-consequent arg ...) ...])]
  [(_ (arg:expr ...)
      [predicate consequent ...]
      ...)
   #'(cond [((on-clause predicate) arg ...)
            =>
            (λ (x)
              (syntax-parameterize ([<result> (make-rename-transformer #'x)])
                (switch-consequent consequent arg ...)
                ...))]
           ...)])

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
                           (.. = (>< string->number)))))
       (check-false (on ("5" "6")
                        (or eq?
                            equal?
                            (with-key string->number =))))
       (check-false (on ("5" "6")
                        (or eq?
                            equal?
                            (.. = (>< string->number))))))
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
                             [< (call (.. + (>< add1)))]
                             [else 'no])
                     10
                     ".. and >< in call position")
       (check-equal? (switch (3 5)
                             [< (call (.. + (>< (.. add1 sqr))))]
                             [else 'no])
                     36
                     ".. and >< in call position"))
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
         "~>"
       (check-equal? (on (5)
                         (~> add1
                             (* 2)
                             number->string
                             (string-append "a" _ "b")))
                     "a12b")
       (check-equal? (on (5 6)
                         (~> (>< add1)
                             (>< number->string)
                             (string-append _ "a" _ "b")))
                     "6a7b")
       (check-equal? (on (5 6)
                         (~> (>< add1)
                             (>< (* 2))
                             +))
                     26)
       (check-equal? (on ("p" "q")
                         (~> (>< (string-append "a" _ "b"))
                             string-append))
                     "apbaqb")
       (check-equal? (switch (3 5)
                             [true. (call (~> (>< add1) *))]
                             [else 'no])
                     24))
     (test-case
         "-<"
       (define (sum lst)
         (apply + lst))

       (check-equal? (on (5)
                         (~> (-< sqr add1)
                             +))
                     31)
       (check-equal? (on ((range 1 10))
                         (~> (-< sum length) /))
                     5)
       (check-equal? (switch (3 5)
                             [true. (call (~> (>< add1) * (-< (/ 2) (/ 3)) +))]
                             [else 'no])
                     20))
     (test-case
         "=="
       (define (sum lst)
         (apply + lst))

       (check-equal? (on (5 7)
                         (~> (== sqr add1)
                             +))
                     33)
       (check-equal? (on ((range 1 10))
                         (~> (-< sum length)
                             (== add1 sub1)
                             +))
                     54)
       (check-equal? (switch (10 12)
                             [true. (call (~> (== (/ 2) (/ 3)) +))]
                             [else 'no])
                     9))
     (test-case
         "high-level circuit elements"
       (test-case
           "splitter"
         (check-equal? (on (5)
                           (~> (splitter 3)
                               +))
                       15)
         (check-equal? (switch (5)
                               [true. (call (~> (splitter 3) +))]
                               [else 'no])
                       15)))
     (test-case
         "template with single argument"
       (check-equal? (switch ((list 1 2 3))
                             [(apply > _) 'yes]
                             [else 'no])
                     'no
                     "apply in predicate")
       (check-equal? (switch ((list 3 2 1))
                             [(apply > _) 'yes]
                             [else 'no])
                     'yes
                     "apply in predicate")
       (check-equal? (switch ((list 3 2 1))
                             [(apply > _) (call (apply + _))]
                             [else 'no])
                     6
                     "apply in consequent")
       (let ((my-sort (λ (less-than? #:key key . vs)
                        (sort (map key vs) less-than?))))
         (check-equal? (switch ((list 2 1 3))
                               [(apply my-sort < _ #:key identity) <result>]
                               [else 'no])
                       (list 1 2 3)
                       "apply in predicate with non-tail arguments")
         (check-equal? (switch ((list 2 1 3))
                               [(.. (> 2) length) (call (apply my-sort < _ #:key identity))]
                               [else 'no])
                       (list 1 2 3)
                       "apply in consequent with non-tail arguments"))
       (check-equal? (on ((list 1 2 3))
                         (map add1 _))
                     (list 2 3 4)
                     "map in predicate")
       (check-equal? (switch ((list 3 2 1))
                             [(apply > _) (call (map add1 _))]
                             [else 'no])
                     (list 4 3 2)
                     "map in consequent")
       (check-equal? (on ((list 1 2 3))
                         (filter odd? _))
                     (list 1 3)
                     "filter in predicate")
       (check-equal? (switch ((list 3 2 1))
                             [(apply > _) (call (filter even? _))]
                             [else 'no])
                     (list 2)
                     "filter in consequent")
       (check-equal? (on ((list "a" "b" "c"))
                         (foldl string-append "" _))
                     "cba"
                     "foldl in predicate")
       (check-equal? (switch ((list 3 2 1))
                             [(apply > _) (call (foldl + 1 _))]
                             [else 'no])
                     7
                     "foldl in consequent"))
     (test-case
         "template with multiple arguments"
       (check-true (on (3 7) (< 1 _ 5 _ 10))
                   "template with multiple arguments")
       (check-false (on (3 5) (< 1 _ 5 _ 10))
                    "template with multiple arguments")
       (check-equal? (switch (3 7)
                             [(< 1 _ 5 _ 10) 'yes]
                             [else 'no])
                     'yes
                     "template with multiple arguments"))
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
       (check-false ((π args (apply > _)) 1 2 3) "apply with packed args")
       (check-true ((π args (apply > _)) 3 2 1) "apply with packed args"))
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
                           [(apply < _) 'a]
                           [else 'b]) 1 2 3)
                     'a
                     "apply with packed args")
       (check-equal? ((λ01 args
                           [(apply < _) 'a]
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
                             [(member _ (list 1 5 4 2 6)) <result>]
                             [else 'hi])
                     (list 2 6))
       (check-equal? (switch (2)
                             [(member _ (list 1 5 4 2 6)) (length <result>)]
                             [else 'hi])
                     2)
       (check-equal? (switch ((list add1 sub1))
                             [car (<result> 5)]
                             [else 'hi])
                     6)
       (check-equal? (switch (2 3)
                             [+ <result>]
                             [else 'hi])
                     5)))))

(module+ test
  (run-tests tests))
