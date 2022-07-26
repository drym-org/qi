#lang racket/base

(provide tests)

(require qi
         rackunit
         rackunit/text-ui
         (only-in math sqr)
         (only-in adjutor values->list)
         racket/function
         "private/util.rkt")

(define tests
  (test-suite
   "switch tests"
   (test-suite
    "Edge/base cases"
    (check-equal? (values->list (switch ())) null "null switch")
    (check-equal? (switch (2)) 2 "trivial switch")
    (check-equal? (switch (2) [negative? sub1]) 2 "no matching clauses")
    (check-equal? (switch (6 5)
                    [< 'yo]
                    [else void])
                  (void)
                  "no matching clause returns input values - must be explicit about e.g. void")
    (check-equal? (switch (5 3)
                    [< (=> (group 1 ⏚ +))]
                    [else -])
                  2
                  "else with preceding =>"))
   (test-suite
    "common"
    (check-equal? (switch (0)
                    [negative? 'bye]
                    [positive? 'hi]
                    [zero? 'later])
                  'later)
    (check-equal? (switch (5 6)
                    [> 'bye]
                    [< 'hi]
                    [else 'yo])
                  'hi)
    (check-equal? (switch (5 5)
                    [> 'bye]
                    [< 'hi]
                    [else 'yo])
                  'yo)
    (check-equal? (switch (5 5 6 7)
                    [> 'bye]
                    [< 'hi]
                    [else 'yo])
                  'yo)
    (check-equal? (switch (5 5 6 7)
                    [>= 'bye]
                    [<= 'hi]
                    [else 'yo])
                  'hi)
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
                  'b)
    (check-equal? (switch (3 7)
                    [(< 1 _ 5 _ 10) 'yes]
                    [else 'no])
                  'yes
                  "template with multiple arguments"))
   (test-suite
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
   (test-suite
    "consequent flows"
    (check-equal? (switch (5)
                    [positive? add1]
                    [else 'no])
                  6)
    (check-equal? (switch (-5)
                    [positive? add1]
                    [else 'no])
                  'no)
    (check-equal? (switch (3 5)
                    [< +]
                    [else 'no])
                  8
                  "n-ary predicate")
    (check-equal? (switch (3 5)
                    [> +]
                    [else 'no])
                  'no
                  "n-ary predicate")
    (check-equal? (switch (3 5)
                    [< (~> (>< add1) +)]
                    [else 'no])
                  10
                  "~> and >< in call position")
    (check-equal? (switch (3 5)
                    [< (~> (>< (~> sqr add1)) +)]
                    [else 'no])
                  36
                  "~> and >< in call position")
    (check-equal? (switch (3 5)
                    [true. (~> (>< add1) *)]
                    [else 'no])
                  24)
    (check-equal? (switch (3 5)
                    [true. (~> (>< sqr) +)]
                    [else 'no])
                  34)
    (check-equal? (switch (3 5)
                    [true. (~> (>< add1) * (-< (/ 2) (/ 3)) +)]
                    [else 'no])
                  20)
    (check-equal? (switch (10 12)
                    [true. (~> (== (/ 2) (/ 3)) +)]
                    [else 'no])
                  9)
    (check-equal? (switch (5)
                    [true. (~> (fanout 3) +)]
                    [else 'no])
                  15)
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
                    [(apply > _) (apply + _)]
                    [else 'no])
                  6
                  "apply in consequent")
    (check-equal? (switch ((list 2 1 3))
                    [(~> length (> 2)) (apply sort < _ #:key identity)]
                    [else 'no])
                  (list 1 2 3)
                  "apply in consequent with non-tail arguments")
    (check-equal? (switch ((list 3 2 1))
                    [(apply > _) (map add1 _)]
                    [else 'no])
                  (list 4 3 2)
                  "map in consequent")
    (check-equal? (switch ((list 3 2 1))
                    [(apply > _) (filter even? _)]
                    [else 'no])
                  (list 2)
                  "filter in consequent")
    (check-equal? (switch ((list 3 2 1))
                    [(apply > _) (foldl + 1 _)]
                    [else 'no])
                  7
                  "foldl in consequent"))
   (test-suite
    "connect"
    (check-equal? (switch (5)
                    [positive? (switch [(and integer? odd?) add1]
                                 [else 'positive])]
                    [else 'no])
                  6)
    (check-equal? (switch (6)
                    [positive? (switch [(and integer? odd?) add1]
                                 [else 'positive])]
                    [else 'no])
                  'positive)
    (check-equal? (switch (-5)
                    [positive? (switch [(and integer? odd?) add1]
                                 [else 'positive])]
                    [else 'no])
                  'no)
    (check-equal? (switch (3 5)
                    [< (switch [(~> - abs (< 3)) +])]
                    [else 'no])
                  8
                  "n-ary predicate")
    (check-equal? (switch (3 8)
                    [< (switch [(~> - abs (< 3)) +]
                         [else 'less])]
                    [else 'no])
                  'less
                  "n-ary predicate")
    (check-equal? (switch (5 3)
                    [< (switch [(~> - abs (< 3)) +]
                         [else 'less])]
                    [else 'no])
                  'no
                  "n-ary predicate"))
   (test-suite
    "result of predicate expression"
    (check-equal? (switch (6)
                    [add1 (=> 1> add1)]
                    [else 'hi])
                  8)
    (check-equal? (switch (2)
                    [(member _ (list 1 5 4 2 6)) (=> 1>)]
                    [else 'hi])
                  (list 2 6))
    (check-equal? (switch (2)
                    [(member _ (list 1 5 4 2 6)) (=> 1> length)]
                    [else 'hi])
                  2)
    (check-equal? (switch ((list add1 sub1))
                    [car (=> (== _ 5) apply)]
                    [else 'hi])
                  6)
    (check-equal? (switch (2 3)
                    [+ (=> 1>)]
                    [else 'hi])
                  5)
    (check-equal? (switch (2 3)
                    [#f 1>]
                    [+ (=> 1>)]
                    [else 'hi])
                  5
                  "=> in the middle somewhere")
    (check-equal? (switch (2 3)
                    [#f (=> 1>)]
                    [+ (=> 1>)]
                    [else 'hi])
                  5
                  "more than one =>")
    (check-equal? (switch ((list 2 1 3))
                    [(apply sort < _ #:key identity) (=> 1>)]
                    [else 'no])
                  (list 1 2 3)
                  "apply in predicate with non-tail arguments"))
   (test-suite
    "divert"
    (check-equal? (switch (4 -1)
                    (% 1> _)
                    [positive? +]
                    [negative? 'hi]
                    [else 'bye])
                  3)
    (check-equal? (switch (4 -1)
                    (% 1> _)
                    [add1 (=> + sqr)]
                    [negative? 'hi]
                    [else 'bye])
                  64)
    (check-equal? (switch (4 -1)
                    (% 1> 2>)
                    [positive? _]
                    [negative? 'hi]
                    [else 'bye])
                  -1
                  "diverting to consequent flows")
    (check-equal? (switch (0 -1)
                    (% 1> 2>)
                    [positive? 'hi]
                    [negative? 'bye])
                  -1
                  "diverting to consequent flows with no matching clauses"))
   (test-suite
    "heterogeneous clauses"
    (check-equal? (switch (-3 5)
                    [> +]
                    [(or% positive? integer?) 'yes]
                    [else 'no])
                  'yes)
    (check-equal? (switch (-3 5)
                    [> +]
                    [(and% positive? integer?) 'yes]
                    [else 'no])
                  'no))
   (test-suite
    "non-flow consequent expressions"
    (check-equal? (switch (0)
                    [negative? (gen (+ 1 2))]
                    [positive? (gen (- 1 2))]
                    [zero? (gen (* 2 3))])
                  6))
   (test-suite
    "switch-lambda tests"
    (check-equal? ((switch-lambda (a . a*)
                     [(memq _ _) 'yes]
                     [else 'no])
                   2 2 3 4)
                  'yes))
   (test-suite
    "define-switch tests"
    (check-equal? (let ()
                    (define-switch ((t n) . n*)
                      [(memq n _) 'yes]
                      [else 'no])
                    (list ((t 1) 1 2 3)
                          ((t 0) 1 2 3)))
                  '(yes no)))))

(module+ main
  (void (run-tests tests)))
