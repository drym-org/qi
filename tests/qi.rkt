#lang racket/base

(require qi
         rackunit
         rackunit/text-ui
         (only-in math sqr)
         racket/list
         racket/string
         racket/function
         "private/util.rkt")

(define tests
  (test-suite
   "qi tests"

   (test-suite
    "flow tests"

    (test-suite
     "core language"
     (test-suite
      "Edge/base cases"
      (check-equal? ((☯)) (void) "non-flow")
      (check-equal? ((☯) 0) (void) "non-flow")
      (check-equal? ((☯) 1 2) (void) "non-flow")
      (check-equal? ((☯ (const 3))) 3 "no arguments")
      (check-equal? ((flow add1) 2) 3 "simple function")
      (check-equal? ((flow 0) 2) 0 "literal (number)")
      (check-equal? ((flow "hi") 5) "hi" "literal (string)")
      (check-equal? ((flow 'hi) 5) 'hi "literal (symbol)")
      (check-equal? ((flow '(+ 1 2)) 5) '(+ 1 2) "literal (quoted list)")
      (check-equal? ((flow `(+ 1 ,(* 2 3))) 5) '(+ 1 6) "literal (quasiquoted list)")
      (check-equal? (syntax->datum ((flow #'(+ 1 2)) 5)) '(+ 1 2) "syntax quoted list")
      (check-equal? ((flow _) 5) 5 "identity flow")
      (check-equal? ((flow (~> _ +)) 5 6) 11 "identity flow"))
     (test-suite
      "unary predicate"
      (check-false ((☯ negative?) 5))
      (check-true ((☯ positive?) 5)))
     (test-suite
      "binary predicate"
      (check-false ((☯ >) 5 6))
      (check-true ((☯ <) 5 6)))
     (test-suite
      "n-ary predicate"
      (check-false ((☯ >) 5 5 6 7))
      (check-false ((☯ <) 5 5 6 7))
      (check-true ((☯ <=) 5 5 6 7)))
     (test-suite
      "one-of?"
      (check-false ((☯ (one-of? "hi" "ola")) "hello"))
      (check-true ((☯ (one-of? "hi" "hello")) "hello")))
     (test-suite
      "predicate under a mapping"
      (check-true ((☯ (~> string->number (< 10))) "5"))
      (check-false ((☯ (~> string->number (> 10))) "5")))
     (test-suite
      "and (conjoin)"
      (check-true ((☯ (and positive? integer?)) 5))
      (check-false ((☯ (and positive? integer?)) 5.4))
      (check-true ((☯ (and (> 5) (< 10))) 6))
      (check-false ((☯ (and (> 5) (< 10))) 4))
      (check-false ((☯ (and (> 5) (< 10))) 14))
      (check-false ((☯ (and _ positive?)) #f) "_ in and"))
     (test-suite
      "or (disjoin)"
      (check-true ((☯ (or positive? odd?)) 6))
      (check-true ((☯ (or positive? odd?)) -5))
      (check-false ((☯ (or positive? odd?)) -6))
      (check-true ((☯ (or eq?
                          equal?
                          (~> (>< string->number) =)))
                   "5.0" "5"))
      (check-false ((☯ (or eq?
                           equal?
                           (~> (>< string->number) =)))
                    "5" "6"))
      (check-true ((☯ (or _ NOT)) #f) "_ in or"))
     (test-suite
      "not (predicate negation)"
      (check-true ((☯ (not positive?)) -5))
      (check-false ((☯ (not positive?)) 5))
      (check-true ((☯ (not _)) #f) "_ in not"))
     (test-suite
      "boolean combinators"
      (check-true ((☯ (and positive?
                           (not even?)))
                   5))
      (check-false ((☯ (and positive?
                            (not odd?)))
                    5))
      (check-true ((☯ (and positive?
                           (or integer?
                               odd?)))
                   5))
      (check-false ((☯ (and positive?
                            (or (> 6)
                                even?)))
                    5))
      (check-true ((☯ (and positive?
                           (or (eq? 3)
                               (eq? 5))))
                   5))
      (check-false ((☯ (and positive?
                            (or (eq? 3)
                                (eq? 6))))
                    5)))
     (test-suite
      "juxtaposed boolean combinators"
      (check-true ((☯ (and% positive?
                            (or (> 10)
                                odd?)))
                   20 5))
      (check-false ((☯ (and% positive?
                             (or (> 10)
                                 even?)))
                    20 5)))
     (test-suite
      "juxtaposed conjoin"
      (check-true ((☯ (and% positive? string?))
                   5 "hi"))
      (check-false ((☯ (and% positive? string?))
                    5 5))
      (check-true ((☯ (and% positive? _))
                   5 "hi"))
      (check-true ((☯ (and% _ string?))
                   5 "hi")))
     (test-suite
      "juxtaposed disjoin"
      (check-true ((☯ (or% positive? string?))
                   5 "hi"))
      (check-true ((☯ (or% positive? string?))
                   -5 "hi"))
      (check-false ((☯ (or% positive? string?))
                    -5 5))
      (check-false ((☯ (or% positive? _))
                    -5 "hi"))
      (check-true ((☯ (or% positive? _))
                   5 "hi"))
      (check-true ((☯ (or% _ string?))
                   5 "hi"))
      (check-false ((☯ (or% _ string?))
                    5 5)))
     (test-suite
      "all"
      (check-true ((☯ (all positive?))
                   3 5))
      (check-false ((☯ (all positive?))
                    3 -5)))
     (test-suite
      "any"
      (check-true ((☯ (any positive?))
                   3 5))
      (check-true ((☯ (any positive?))
                   3 -5))
      (check-false ((☯ (any positive?))
                    -3 -5)))
     (test-suite
      "none"
      (check-true ((☯ (none positive?))
                   -3 -5))
      (check-false ((☯ (none positive?))
                    3 -5))
      (check-false ((☯ (none positive?))
                    3 5)))
     (test-suite
      "all?"
      (check-true ((☯ all?) 3))
      (check-false ((☯ all?) #f))
      (check-true ((☯ all?) 3 5 7))
      (check-false ((☯ all?) 3 #f 5)))
     (test-suite
      "any?"
      (check-true ((☯ any?) 3))
      (check-false ((☯ any?) #f))
      (check-true ((☯ any?) 3 5 7))
      (check-true ((☯ any?) 3 #f 5))
      (check-true ((☯ any?) #f #f 5))
      (check-false ((☯ any?) #f #f #f)))
     (test-suite
      "none?"
      (check-false ((☯ none?) 3))
      (check-true ((☯ none?) #f))
      (check-false ((☯ none?) 3 5 7))
      (check-false ((☯ none?) 3 #f 5))
      (check-false ((☯ none?) #f #f 5))
      (check-true ((☯ none?) #f #f #f)))
     (test-suite
      "collect"
      (check-equal? ((☯ (~> collect (string-join "")))
                     "a" "b" "c")
                    "abc")
      (check-equal? ((☯ (~> ▽ (string-join "")))
                     "a" "b" "c")
                    "abc")
      (check-equal? ((☯ (~> ▽ (string-join "")))
                     "a")
                    "a")
      (check-equal? ((☯ (~> ▽ (string-join ""))))
                    ""))
     (test-suite
      "sep"
      (check-equal? ((☯ (~> △ +))
                     null)
                    0)
      (check-equal? ((☯ (~> sep +))
                     null)
                    0)
      (check-equal? ((☯ △)
                     (list 1))
                    1)
      (check-equal? ((☯ (~> △ +))
                     (list 1 2 3 4))
                    10)
      (check-exn exn:fail:contract?
                 (thunk ((☯ (~> △ +))
                         #(1 2 3 4)))
                 10))
     (test-suite
      "gen"
      (check-equal? ((☯ (gen 5)))
                    5)
      (check-equal? ((☯ (gen 5)) 3)
                    5)
      (check-equal? ((☯ (gen 5)) 3 7)
                    5)
      (check-equal? ((☯ (~> (>< (gen 5)) +)) 3 4)
                    10)
      (check-equal? ((☯ (~> (gen 3 4 5) +)))
                    12))
     (test-suite
      "escape hatch"
      (check-equal? ((☯ (esc (first (list + *)))) 3 7)
                    10
                    "normal racket expressions"))
     (test-suite
      "elementary boolean gates"
      (test-suite
       "AND"
       (check-false ((☯ AND) #f))
       (check-true ((☯ AND) 3))
       (check-true ((☯ AND) 3 5 7))
       (check-false ((☯ AND) 3 #f 5))
       (check-false ((☯ AND) #f #f 5))
       (check-false ((☯ AND) #f #f #f)))
      (test-suite
       "OR"
       (check-false ((☯ OR) #f))
       (check-true ((☯ OR) 3))
       (check-true ((☯ OR) 3 5 7))
       (check-true ((☯ OR) 3 #f 5))
       (check-true ((☯ OR) #f #f 5))
       (check-false ((☯ OR) #f #f #f)))
      (test-suite
       "NOT"
       (check-false ((☯ NOT) 3))
       (check-true ((☯ NOT) #f)))
      (test-suite
       "NAND"
       (check-true ((☯ NAND) #f))
       (check-false ((☯ NAND) 3))
       (check-false ((☯ NAND) 3 5 7))
       (check-true ((☯ NAND) 3 #f 5))
       (check-true ((☯ NAND) #f #f 5))
       (check-true ((☯ NAND) #f #f #f)))
      (test-suite
          "NOR"
        (check-true ((☯ NOR) #f))
        (check-false ((☯ NOR) 3))
        (check-false ((☯ NOR) 3 5 7))
        (check-false ((☯ NOR) 3 #f 5))
        (check-false ((☯ NOR) #f #f 5))
        (check-true ((☯ NOR) #f #f #f)))
      (test-suite
       "XOR"
       (check-false ((☯ XOR) #f))
       (check-true ((☯ XOR) 3))
       (check-true ((☯ XOR) #f 3))
       (check-true ((☯ XOR) 3 #f))
       (check-false ((☯ XOR) 3 5))
       (check-false ((☯ XOR) #f #f))
       (check-false ((☯ XOR) #f #f #f))
       (check-true ((☯ XOR) #f #f 3))
       (check-true ((☯ XOR) #f 3 #f))
       (check-false ((☯ XOR) #f 3 5))
       (check-true ((☯ XOR) 3 #f #f))
       (check-false ((☯ XOR) 3 #f 5))
       (check-false ((☯ XOR) 3 5 #f))
       (check-true ((☯ XOR) 3 5 7)))
      (test-suite
       "XNOR"
       (check-true ((☯ XNOR) #f))
       (check-false ((☯ XNOR) 3))
       (check-false ((☯ XNOR) #f 3))
       (check-false ((☯ XNOR) 3 #f))
       (check-true ((☯ XNOR) 3 5))
       (check-true ((☯ XNOR) #f #f))
       (check-true ((☯ XNOR) #f #f #f))))
     (test-suite
      "interactions between components"
      (test-suite
       "prisms"
       (check-equal? ((☯ (~> △ ▽)) (list 1 2 3))
                     (list 1 2 3))
       (check-equal? ((☯ (~> ▽ △ string-append)) "a" "b" "c")
                     "abc"))))

    (test-suite
     "routing forms"
     (test-suite
      "~>"
      (check-equal? ((☯ (~> add1
                            (* 2)
                            number->string
                            (string-append "a" _ "b")))
                     5)
                    "a12b")
      (check-equal? ((☯ (~> (>< add1)
                            (>< number->string)
                            (string-append _ "a" _ "b")))
                     5 6)
                    "6a7b")
      (check-equal? ((☯ (~> (>< add1)
                            (>< (* 2))
                            +))
                     5 6)
                    26)
      (check-equal? ((☯ (~> (>< (string-append "a" _ "b"))
                            string-append))
                     "p" "q")
                    "apbaqb")
      (check-equal? ((☯ (~> (string-append "a" "b")))
                     "p" "q")
                    "pqab"
                    "threading without template")
      (check-equal? ((☯ (~> (>< (string-append "a" "b"))
                            string-append))
                     "p" "q")
                    "pabqab"
                    "threading without template")
      (check-equal? ((☯ (thread add1
                                (* 2)
                                number->string
                                (string-append "a" _ "b")))
                     5)
                    "a12b"
                    "named threading form"))
     (test-suite
      "~>>"
      (check-equal? ((☯ (~>> add1
                             (* 2)
                             number->string
                             (string-append "a" _ "b")))
                     5)
                    "a12b")
      (check-equal? ((☯ (~>> (>< add1)
                             (>< number->string)
                             (string-append _ "a" _ "b")))
                     5 6)
                    "6a7b")
      (check-equal? ((☯ (~>> (>< add1)
                             (>< (* 2))
                             +))
                     5 6)
                    26)
      (check-equal? ((☯ (~>> (>< (string-append "a" _ "b"))
                             string-append))
                     "p" "q")
                    "apbaqb")
      (check-equal? ((☯ (~>> (string-append "a" "b")))
                     "p" "q")
                    "abpq"
                    "right-threading without template")
      ;; TODO: propagate threading side to nested clauses
      ;; (check-equal? (on ("p" "q")
      ;;                   (~>> (>< (string-append "a" "b"))
      ;;                        string-append))
      ;;               "abpabq"
      ;;               "right-threading without template")
      (check-equal? ((☯ (thread-right add1
                                      (* 2)
                                      number->string
                                      (string-append "a" _ "b")))
                     5)
                    "a12b"
                    "named threading form"))
     (test-suite
      "crossover"
      (check-equal? ((☯ (~> X string-append))
                     "a" "b")
                    "ba")
      (check-equal? ((☯ (~> crossover string-append))
                     "a" "b")
                    "ba")
      (check-equal? ((☯ X) "a")
                    "a"))
     (test-suite
      "-<"
      (check-equal? ((☯ (~> (-< sqr add1)
                            +))
                     5)
                    31)
      (check-equal? ((☯ (~> (-< sum length) /))
                     (range 1 10))
                    5)
      (check-equal? ((☯ (~> (-< _ add1)
                            +))
                     5)
                    11
                    "tee with don't-care")
      (check-equal? ((☯ (~> (-< ⏚)
                            +))
                     5 7)
                    0
                    "tee with arity-nullifying clause")
      (check-equal? ((☯ (~> (-< (-< _ _) _)
                            +))
                     5)
                    15
                    "tee with arity-increasing clause")
      (check-equal? ((☯ (~> (tee sqr add1)
                            +))
                     5)
                    31
                    "named tee junction form"))
     (test-suite
         "=="
       (check-equal? ((☯ (~> (== sqr add1)
                             +))
                      5 7)
                     33)
       (check-equal? ((☯ (~> (-< sum length)
                             (== add1 sub1)
                             +))
                      (range 1 10))
                     54)
       (check-equal? ((☯ (~> (== _ add1)
                             +))
                      5 7)
                     13
                     "relay with don't-care")
       (check-equal? ((☯ (~> (== _ _)
                             +))
                      5 7)
                     12
                     "relay with don't-care")
       (check-equal? ((☯ (~> (== ⏚ add1)
                             +))
                      5 7)
                     8
                     "relay with arity-nullifying clause")
       (check-equal? ((☯ (~> (== (-< _ _) add1)
                             +))
                      5 7)
                     18
                     "relay with arity-increasing clause")
       (check-exn exn:fail?
                  (thunk ((☯ (~> (== ⏚ add1)
                                 +))
                          5 7 8))
                  "relay elements must be in one-to-one correspondence with input")
       (check-equal? ((☯ (~> (relay sqr add1)
                             +))
                      5 7)
                     33
                     "named relay form"))
     (test-suite
      "ground"
      (check-equal? ((☯ (-< ⏚ add1))
                     5)
                    6)
      (check-equal? ((☯ (-< ground add1))
                     5)
                    6)))

    (test-suite
     "partial application"
     (test-suite
      "implicitly curried forms"
      (test-suite
       "eq?"
       (check-false ((☯ (eq? 5)) 6))
       (check-true ((☯ (eq? 5)) 5)))
      (test-suite
       "equal?"
       (check-false ((☯ (equal? "hello")) "bye"))
       (check-true ((☯ (equal? "hello")) "hello")))
      (test-suite
       "<"
       (check-false ((☯ (< 5)) 5))
       (check-true ((☯ (< 10)) 5)))
      (test-suite
       "<="
       (check-false ((☯ (<= 1)) 5))
       (check-true ((☯ (<= 10)) 5))
       (check-true ((☯ (<= 5)) 5)))
      (test-suite
       ">"
       (check-false ((☯ (> 5)) 5))
       (check-true ((☯ (> 1)) 5)))
      (test-suite
       ">="
       (check-false ((☯ (>= 10)) 5))
       (check-true ((☯ (>= 1)) 5))
       (check-true ((☯ (>= 5)) 5)))
      (test-suite
       "="
       (check-true ((☯ (= 5)) 5))
       (check-false ((☯ (= 10)) 5)))
      (check-equal? ((☯ (string-append "b"))
                     "a")
                    "ab")
      (check-equal? ((☯ (string-append "c" "d"))
                     "a" "b")
                    "abcd")
      (check-equal? ((☯ (~>> (map add1)))
                     (list 1 2 3))
                    (list 2 3 4)
                    "curried map")
      (check-equal? ((☯ (~>> (filter odd?)))
                     (list 1 2 3))
                    (list 1 3)
                    "curried filter")
      (check-equal? ((☯ (~>> (foldl string-append "")))
                     (list "a" "b" "c"))
                    "cba"
                    "curried foldl")
      (check-exn exn:fail?
                 (thunk ((☯ (+))
                         5 7 8))
                 "function isn't curried when no arguments are provided"))
     (test-suite
      "simple template"
      (check-equal? ((☯ (+ __))) 0)
      (check-equal? ((☯ (string-append __))
                     "a" "b")
                    "ab")
      (check-equal? ((☯ (string-append "a" __))
                     "b" "c")
                    "abc")
      (check-equal? ((☯ (string-append __ "c"))
                     "a" "b")
                    "abc"))
     (test-suite
      "template with single argument"
      (check-false ((☯ (apply > _))
                    (list 1 2 3)))
      (check-true ((☯ (apply > _))
                   (list 3 2 1)))
      (check-equal? ((☯ (map add1 _))
                     (list 1 2 3))
                    (list 2 3 4)
                    "map in predicate")
      (check-equal? ((☯ (filter odd? _))
                     (list 1 2 3))
                    (list 1 3)
                    "filter in predicate")
      (check-equal? ((☯ (foldl string-append "" _))
                     (list "a" "b" "c"))
                    "cba"
                    "foldl in predicate"))
     (test-suite
      "template with multiple arguments"
      (check-true ((☯ (< 1 _ 5 _ 10)) 3 7)
                  "template with multiple arguments")
      (check-false ((☯ (< 1 _ 5 _ 10)) 3 5)
                   "template with multiple arguments")))

    (test-suite
     "conditionals"
     (test-suite
      "if"
      (check-equal? ((☯ (if sub1 add1))
                     negative?
                     5)
                    6
                    "control form of if, where the predicate is an input")
      (check-equal? ((☯ (if sub1 add1))
                     positive?
                     5)
                    4
                    "control form of if, where the predicate is an input")
      (check-equal? ((☯ (if + -))
                     <
                     5 6)
                    11
                    "control form of if, where the predicate is an input")
      (check-equal? ((☯ (if + -))
                     >
                     5 6)
                    -1
                    "control form of if, where the predicate is an input")
      (check-equal? ((☯ (if negative? sub1 add1))
                     5)
                    6)
      (check-equal? ((☯ (if negative? sub1 add1))
                     -5)
                    -6)
      (check-equal? ((☯ (if negative? sub1 _))
                     5)
                    5)
      (check-equal? ((☯ (if < + -))
                     5 6)
                    11)
      (check-equal? ((☯ (if < + -))
                     6 5)
                    1)
      (check-equal? ((☯ (if (< 10) _ (gen 0)))
                     5)
                    5)
      (check-equal? ((☯ (if (< 10) _ (gen 0)))
                     15)
                    0))
     (test-suite
      "when"
      (check-equal? ((☯ (when positive? add1))
                     5)
                    6)
      (check-equal? ((☯ (~> (when positive? add1) +))
                     -5)
                    0))
     (test-suite
      "unless"
      (check-equal? ((☯ (~> (unless positive? add1) +))
                     5)
                    0)
      (check-equal? ((☯ (unless positive? add1))
                     -5)
                    -4))
     (test-suite
      "switch"
      (check-equal? ((☯ (~> (switch) +)))
                    0)
      (check-equal? ((☯ (switch [negative? sub1]))
                     -5)
                    -6)
      (check-equal? ((☯ (~> (switch [negative? sub1]) +))
                     5)
                    0)
      (check-equal? ((☯ (switch [negative? sub1] [else add1]))
                     5)
                    6)
      (check-equal? ((☯ (switch [negative? sub1] [else add1]))
                     -5)
                    -6)
      (check-equal? ((☯ (switch [< +] [else -]))
                     5 6)
                    11)
      (check-equal? ((☯ (switch [< +] [else -]))
                     6 5)
                    1)
      (check-equal? ((☯ (switch [< +] [> -] [else _]))
                     5 6)
                    11)
      (check-equal? ((☯ (switch [< +] [> -] [else _]))
                     6 5)
                    1)
      (check-equal? ((☯ (switch [< +] [> -] [else 0]))
                     6 6)
                    0)
      (check-equal? ((☯ (switch [< +] [> -] [= 0]))
                     6 6)
                    0)
      (check-equal? ((☯ (~> (switch [< +] [> -]) +))
                     6 6)
                    0)
      (check-equal? ((☯ (switch [(< 10) _] [else (gen 0)]))
                     5)
                    5)
      (check-equal? ((☯ (switch [(< 10) _] [else (gen 0)]))
                     15)
                    0)
      (test-suite
       "divert"
       (check-equal? ((☯ (~> (switch (% _ _)) +)))
                     0)
       (check-equal? ((☯ (switch (% 1> _)
                           [positive? +]
                           [negative? 'hi]
                           [else 'bye])) 4 -1)
                     3)
       (check-equal? ((☯ (switch (divert 1> _)
                           [positive? +]
                           [negative? 'hi]
                           [else 'bye])) 4 -1)
                     3
                     "divert word form")
       (check-equal? ((☯ (switch (% 1> _)
                           [positive? +]
                           [negative? 'hi]
                           [else 'bye])) -2 -1)
                     'hi)
       (check-equal? ((☯ (switch (% 1> _)
                           [positive? +]
                           [negative? 'hi]
                           [else 'bye])) 0 -1)
                     'bye)
       (check-equal? ((☯ (switch (% 1> _)
                           [add1 (=> + sqr)]
                           [negative? 'hi]
                           [else 'bye])) 4 -1)
                     64)
       (check-equal? ((☯ (switch (% 1> 2>)
                           [positive? _]
                           [negative? 'hi]
                           [else 'bye])) 4 -1)
                     -1
                     "diverting to consequent flows"))
      (test-suite
          "result of predicate expression"
        (check-equal? ((☯ (switch
                            [add1 (=> 1> add1)]
                            [else 'hi]))
                       6)
                      8)
        (check-equal? ((☯ (switch
                            [(member (list 1 5 4 2 6)) (=> 1>)]
                            [else 'hi]))
                       2)
                      (list 2 6))
        (check-equal? ((☯ (switch
                            [(member (list 1 5 4 2 6)) (=> 1> length)]
                            [else 'hi]))
                       2)
                      2)
        (check-equal? ((☯ (switch
                            [car (=> (== _ 5) apply)]
                            [else 'hi]))
                       (list add1 sub1))
                      6)
        (check-equal? ((☯ (switch
                            [+ (=> 1>)]
                            [else 'hi]))
                       2 3)
                      5)
        (check-equal? ((☯ (switch
                            [(~>> △ (sort < #:key identity)) (=> 1>)]
                            [else 'no]))
                       (list 2 1 3))
                      (list 1 2 3)
                      "apply in predicate with non-tail arguments")))
     (test-suite
      "sieve"
      (check-equal? ((☯ (~> (sieve positive? add1 (const -1)) +))
                     1 -2)
                    1)
      (check-equal? ((☯ (~> (sieve positive? + (+ 2)) +))
                     1 2 -3 4)
                    6)
      (check-equal? ((☯ (~> (sieve positive? + (const 0)) +))
                     1 2 3 4)
                    10)
      (check-equal? ((☯ (~> (sieve negative? ⏚ ⏚)
                            +))
                     1 3 5 7)
                    0
                    "sieve with arity-nullifying clause")
      (check-equal? ((☯ (~> (sieve positive? (>< (-< _ _)) (>< _))
                            +))
                     1 -3 5)
                    9
                    "sieve with arity-increasing clause"))
     (test-suite
      "gate"
      (check-equal? ((☯ (gate positive?))
                     5)
                    5)
      (check-equal? ((☯ (-< (gate negative?) (gen 0)))
                     5)
                    0)
      (check-equal? ((☯ (~> (gate <)
                            +))
                     5 6)
                    11)))
    (test-suite
     "high-level circuit elements"
     (test-suite
      "input aliases"
      (check-equal? ((☯ (~> 1>))
                     1 2 3 4 5 6 7 8 9)
                    1)
      (check-equal? ((☯ (~> 2>))
                     1 2 3 4 5 6 7 8 9)
                    2)
      (check-equal? ((☯ (~> 3>))
                     1 2 3 4 5 6 7 8 9)
                    3)
      (check-equal? ((☯ (~> 4>))
                     1 2 3 4 5 6 7 8 9)
                    4)
      (check-equal? ((☯ (~> 5>))
                     1 2 3 4 5 6 7 8 9)
                    5)
      (check-equal? ((☯ (~> 6>))
                     1 2 3 4 5 6 7 8 9)
                    6)
      (check-equal? ((☯ (~> 7>))
                     1 2 3 4 5 6 7 8 9)
                    7)
      (check-equal? ((☯ (~> 8>))
                     1 2 3 4 5 6 7 8 9)
                    8)
      (check-equal? ((☯ (~> 9>))
                     1 2 3 4 5 6 7 8 9)
                    9))
     (test-suite
      "fanout"
      (check-equal? ((☯ (~> (fanout 3)
                            +))
                     5)
                    15))
     (test-suite
      "inverter"
      (check-false ((☯ (~> inverter
                           AND))
                    5 6))
      (check-true ((☯ (~> inverter
                          OR))
                   #f #t)))
     (test-suite
      "feedback"
      (check-equal? ((☯ (feedback sqr 2))
                     5)
                    625)
      (check-equal? ((☯ (~> + (feedback add1 5)))
                     5 6)
                    16)
      (check-equal? ((☯ (~> (feedback (>< add1) 3)
                            +))
                     2 3)
                    11)
      (check-equal? ((☯ (~> (feedback (== add1 sub1) 3)
                            +))
                     2 3)
                    5))
     (test-suite
      "group"
      (check-equal? ((☯ (~> (group 0 (const 5) +) +))
                     1 2)
                    8)
      (check-equal? ((☯ (~> (group 1 add1 sub1) +))
                     1 2)
                    3)
      (check-equal? ((☯ (~> (group 3 * add1) +))
                     1 2 3 4)
                    11)
      (check-equal? ((☯ (~> (group 2
                                   (~> (>< add1) +)
                                   add1)
                            +))
                     4 5 6)
                    18)
      (check-equal? ((☯ (~> (group 2 ⏚ ⏚)
                            +))
                     1 3 5 7 9)
                    0
                    "group with arity-nullifying clause")
      (check-equal? ((☯ (~> (group 2 (>< (-< _ _)) (>< _))
                            +))
                     1 3 5 7 9)
                    29
                    "group with arity-increasing clause")
      (check-equal? ((☯ (~> (group 2 (>< sqr) _) +))
                     1 2 3)
                    8
                    "group with don't-care"))
     (test-suite
      "select"
      (check-equal? ((☯ (~> (select) +))
                     1)
                    0)
      (check-equal? ((☯ (select 1))
                     1)
                    1)
      (check-equal? ((☯ (select 2))
                     1 2 3)
                    2)
      (check-equal? ((☯ (select 3))
                     1 2 3)
                    3)
      (check-equal? ((☯ (~> (select 1 3)
                            string-append))
                     "1" "2" "3")
                    "13")
      (check-equal? ((☯ (~> (select 3 1)
                            string-append))
                     "1" "2" "3")
                    "31"))
     (test-suite
      "block"
      (check-equal? ((☯ (~> (block) list))
                     1 2)
                    (list 1 2))
      (check-equal? ((☯ (~> (block 1) list))
                     1)
                    null)
      (check-equal? ((☯ (~> (block 2) list))
                     1 2 3)
                    (list 1 3))
      (check-equal? ((☯ (~> (block 3) list))
                     1 2 3)
                    (list 1 2))
      (check-equal? ((☯ (~> (block 1 3) list))
                     1 2 3)
                    (list 2))
      (check-equal? ((☯ (~> (block 3 1) list))
                     1 2 3)
                    (list 2)))
     (test-suite
      "bundle"
      (check-equal? ((☯ (~> (bundle () + sqr) +))
                     3)
                    9)
      (check-equal? ((☯ (bundle (1) sqr _))
                     3)
                    9)
      (check-equal? ((☯ (bundle (2) _ ⏚))
                     1 2 3)
                    2)
      (check-equal? ((☯ (bundle (3) _ ⏚))
                     1 2 3)
                    3)
      (check-equal? ((☯ (~> (bundle (1 3) string-append ⏚)))
                     "1" "2" "3")
                    "13")
      (check-equal? ((☯ (~> (bundle (3 1) string-append _) string-append))
                     "1" "2" "3")
                    "312"))
     (test-suite
      "effect"
      (check-equal? ((☯ (ε sub1 add1))
                     5)
                    6)
      (check-equal? (let ([sv (void)])
                      ((☯ (ε (~> sub1 (esc (λ (x) (set! sv x))))))
                       5)
                      sv)
                    4
                    "pure side effect")
      (let ([a 10])
        (check-equal? ((☯ (ε (esc (λ (_)
                                    (set! a (add1 a))))
                             add1))
                       5)
                      6)
        (check-equal? a 11))))

    (test-suite
     "higher-order flows"
     (test-suite
      "><"
      (check-equal? ((☯ (~> >< +))
                     sqr 3 5)
                    34)
      (check-equal? ((☯ (~> (>< sqr)
                            +))
                     3 5)
                    34)
      (check-equal? ((☯ (~> (>< _)
                            +))
                     3 5)
                    8
                    "amp with don't-care")
      (check-equal? ((☯ (~> (>< ⏚)
                            +))
                     5 7)
                    0
                    "amp with arity-nullifying clause")
      (check-equal? ((☯ (~> (>< (-< _ _))
                            +))
                     5)
                    10
                    "amp with arity-increasing clause")
      (check-equal? ((☯ (~> (amp sqr)
                            +))
                     3 5)
                    34
                    "named amplification form"))
     (test-suite
      "pass"
      (check-equal? ((☯ (~> pass +))
                     positive? -3 5 2)
                    7)
      (check-equal? ((☯ (~> (pass positive?)
                            +))
                     -3 5 2)
                    7)
      (check-equal? ((☯ (~> (pass positive?)
                            +))
                     -5 -7)
                    0
                    "pass with arity-nullifying clause"))
     (test-suite
      "left fold >>"
      (check-equal? ((☯ (~> (>> +))) 1 2 3 4)
                    10)
      (check-equal? ((☯ (~> (>> + 1))) 1 2 3 4)
                    11)
      (check-equal? ((☯ (~> (>> cons null))) 1 2 3 4)
                    (list 4 3 2 1))
      (check-equal? ((☯ (~> (>> (flip cons) null))) 1 2 3 4)
                    '((((() . 1) . 2) . 3) . 4))
      (check-equal? ((☯ (~> (-< (gen cons) (gen null) (gen 1 2 3 4)) >>)))
                    (list 4 3 2 1)))
     (test-suite
      "right fold <<"
      (check-equal? ((☯ (~> (<< +))) 1 2 3 4)
                    10)
      (check-equal? ((☯ (~> (<< + 1))) 1 2 3 4)
                    11)
      (check-equal? ((☯ (~> (<< cons null))) 1 2 3 4)
                    (list 1 2 3 4))
      (check-equal? ((☯ (~> (<< (flip cons) null))) 1 2 3 4)
                    '((((() . 4) . 3) . 2) . 1))
      (check-equal? ((☯ (~> (-< (gen cons) (gen null) (gen 1 2 3 4)) <<)))
                    (list 1 2 3 4)))
     (test-suite
      "loop"
      (check-equal? ((☯ (~> (loop (~> ▽ (not null?))
                                  sqr)
                            ▽)) 1 2 3)
                    (list 1 4 9))
      (check-equal? ((☯ (~> (loop (~> ▽ (not null?))
                                  sqr
                                  +
                                  0))) 1 2 3)
                    14)
      (check-equal? ((☯ (~> (loop sqr) ▽))
                     1 2 3)
                    (list 1 4 9)))
     (test-suite
      "loop2"
      (check-equal? ((☯ (~> (loop2 (~> 1> (not null?))
                                   sqr
                                   cons)))
                     (list 1 2 3) null)
                    (list 9 4 1))
      (check-equal? ((☯ (~> (loop2 (~> 1> (not null?))
                                   sqr
                                   +)))
                     (list 1 2 3)
                     0)
                    14))
     (test-suite
      "apply"
      (check-equal? ((☯ (~> (-< (gen +) 2 3)
                            apply)))
                    5)
      (check-equal? (parameterize ([current-namespace (make-base-empty-namespace)])
                      (namespace-require 'racket/base)
                      (namespace-require 'math)
                      (namespace-require 'qi)
                      ((☯ (~> (-< (~> '(☯ (~> sqr add1))
                                      (eval (current-namespace)))
                                  3)
                              apply))))
                    10)))
    (test-suite
     "arity modulating forms"
     (check-true ((☯ (and% positive? even?))
                  5 6)
                 "and% arity propagation")
     (check-true ((☯ (or% positive? even?))
                  5 6)
                 "or% arity propagation")
     (check-equal? ((☯ (~> (>< add1)
                           +))
                    5 6)
                   13
                   ">< arity propagation")
     (check-equal? ((☯ (~> (== add1 add1)
                           +))
                    5 6)
                   13
                   "== arity propagation")
     (let ([add-two (procedure-reduce-arity + 2)])
       (check-equal? ((☯ (~> (group 2 add-two add1)
                             *))
                      5 6 7)
                     88
                     "group arity propagation")))

    (test-suite
     "runtime arity changes"
     (check-equal? ((☯ (~>> list (findf even?) (if number? _ (gen 0)) sqr))
                    1 3 5)
                   0
                   "runtime arity changes in threading form")
     (check-equal? ((☯ (~>> list (findf even?) (if number? _ (gen 0)) sqr))
                    1 4 5)
                   16
                   "runtime arity changes in threading form")
     (check-false ((☯ (~>> list (-< (findf positive? _) (gen 0)) (and% even? number?)))
                   -1 3 5)
                  "runtime arity changes in threading form")
     (check-true ((☯ (~>> list (-< (findf positive? _) (gen 0)) (or% even? number?)))
                  -1 3 5)
                 "runtime arity changes in threading form")
     (check-equal? ((☯ (~>> list (findf even?) (>< add1)))
                    1 4 5)
                   5
                   "runtime arity changes in threading form")
     (check-equal? ((☯ (~>> list (findf even?) (== add1)))
                    1 4 5)
                   5
                   "runtime arity changes in threading form")
     (check-equal? ((☯ (~>> list (findf even?) number->string (string-append "a" __ "b")))
                    1 4 5)
                   "a4b"
                   "runtime arity changes in threading form")
     (check-equal? ((☯ (~> (pass positive?) +))
                    1 -3 5)
                   6
                   "runtime arity changes in threading form")))

   (test-suite
    "on tests"
    (test-suite
     "Edge/base cases"
     (check-equal? (on (0))
                   (void)
                   "no clauses, unary")
     (check-equal? (on (5 5))
                   (void)
                   "no clauses, binary")
     (check-equal? (on ()
                     (const 3))
                   3
                   "no arguments"))
    (test-suite
     "smoke tests"
     (check-equal? (on (2) add1) 3)
     (check-equal? (on (2) (~> sqr add1)) 5)
     (check-equal? (on (2 3) (~> (>< sqr) +)) 13)
     (check-true (on (2) (eq? 2)))
     (check-true (on (2 -3) (and% positive? negative?)))
     (check-equal? (on (2) (if positive? add1 sub1)) 3)))

   (test-suite
    "switch tests"
    (test-suite
     "Edge/base cases"
     (check-equal? (switch (6 5)
                     [< 'yo]
                     [else void])
                   (void)
                   "no matching clause returns no values - must be explicit about e.g. void")
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
                   "diverting to consequent flows"))
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
                   6)))

   (test-suite
    "threading tests"
    (test-suite
     "Edge/base cases"
     (check-equal? (~> ()) (void))
     (check-equal? (~>> ()) (void))
     (check-equal? (~> () (const 5)) 5)
     (check-equal? (~>> () (const 5)) 5)
     ;; when no functions to thread through are provided,
     ;; we could either (1) return void, (2) return no values
     ;; at all, or (3) return the input values themselves.
     ;; the standard threading behavior does (3)
     ;; while at the moment the present form does (1)
     (check-equal? (~> (4)) (void))
     (check-equal? (~>> (4)) (void))
     (check-equal? (~> (4 5 6)) (void))
     (check-equal? (~>> (4 5 6)) (void)))
    (test-suite
     "smoke"
     (check-equal? (~> (3) sqr add1) 10)
     (check-equal? (~>> (3) sqr add1) 10)
     (check-equal? (~> (3 4) + number->string (string-append "a")) "7a")
     (check-equal? (~>> (3 4) + number->string (string-append "a")) "a7")
     (check-equal? (~> (5 20 3)
                       (group 1
                              (~>
                               add1
                               sqr)
                              *)
                       (>< number->string)
                       (string-append "a:" _ "b:" _))
                   "a:36b:60")))

   (test-suite
    "definition forms"
    (test-suite
     "let/flow"
     (check-equal? (let/flow ([x 5]
                              [y 3])
                     (~> + sqr add1))
                   65))
    (test-suite
     "let/switch"
     (check-equal? (let/switch ([x 5]
                                [y 3])
                     [(~> + (> 10)) 'hi]
                     [else 'bye])
                   'bye))
    (test-suite
     "predicate lambda"
     (check-true ((π (x)
                    (and positive? integer?))
                  5))
     (check-false ((π (x)
                     (and positive? integer?))
                   -5))
     (check-false ((π (x)
                     (and positive? integer?))
                   5.3))
     (check-true ((π (x y)
                    (or < =))
                  5 6))
     (check-true ((π (x y)
                    (or < =))
                  5 5))
     (check-false ((π (x y)
                     (or < =))
                   5 4))
     (check-true ((π (x) (and (> 5) (< 10))) 7))
     (check-false ((π (x) (and (> 5) (< 10))) 2))
     (check-false ((π (x) (and (> 5) (< 10))) 12))
     (check-true ((π args list?) 1 2 3) "packed args")
     (check-false ((π args (~> length (> 3))) 1 2 3) "packed args")
     (check-true ((π args (~> length (> 3))) 1 2 3 4) "packed args")
     (check-false ((π args (apply > _)) 1 2 3) "apply with packed args")
     (check-true ((π args (apply > _)) 3 2 1) "apply with packed args"))
    (test-suite
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
                         [(~> length (> 3)) 'a]
                         [else 'b]) 1 2 3)
                   'b
                   "packed args")
     (check-equal? ((λ01 args
                         [(~> length (> 3)) 'a]
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
                   "apply with packed args")))))

(module+ test
  (just-do
   (run-tests tests)))
