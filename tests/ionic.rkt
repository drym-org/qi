#lang racket/base

(require ionic
         rackunit
         rackunit/text-ui
         (only-in math sqr)
         racket/list
         racket/string
         racket/function
         "private/util.rkt")

(define tests
  (test-suite
   "ionic tests"

   (test-suite
    "flow tests"

    (test-suite
     "core language"
     (test-case
         "Edge/base cases"
       (check-equal? ((☯)) (void) "non-flow")
       (check-equal? ((☯) 0) (void) "non-flow")
       (check-equal? ((☯) 1 2) (void) "non-flow")
       (check-equal? ((☯ (const 3))) 3 "no arguments")
       (check-equal? ((flow add1) 2) 3))
     (test-case
         "unary predicate"
       (check-false ((☯ negative?) 5))
       (check-true ((☯ positive?) 5)))
     (test-case
         "binary predicate"
       (check-false ((☯ >) 5 6))
       (check-true ((☯ <) 5 6)))
     (test-case
         "n-ary predicate"
       (check-false ((☯ >) 5 5 6 7))
       (check-false ((☯ <) 5 5 6 7))
       (check-true ((☯ <=) 5 5 6 7)))
     (test-case
         "one-of?"
       (check-false ((☯ (one-of? "hi" "ola")) "hello"))
       (check-true ((☯ (one-of? "hi" "hello")) "hello")))
     (test-case
         "predicate under a mapping"
       (check-true ((☯ (with-key string->number (< 10))) "5"))
       (check-false ((☯ (with-key string->number (> 10))) "5")))
     (test-case
         "and (conjoin)"
       (check-true ((☯ (and positive? integer?)) 5))
       (check-false ((☯ (and positive? integer?)) 5.4))
       (check-true ((☯ (and (> 5) (< 10))) 6))
       (check-false ((☯ (and (> 5) (< 10))) 4))
       (check-false ((☯ (and (> 5) (< 10))) 14))
       (check-false ((☯ (and _ positive?)) #f) "_ in and"))
     (test-case
         "or (disjoin)"
       (check-true ((☯ (or positive? odd?)) 6))
       (check-true ((☯ (or positive? odd?)) -5))
       (check-false ((☯ (or positive? odd?)) -6))
       (check-true ((☯ (or eq?
                           equal?
                           (with-key string->number =)))
                    "5.0" "5"))
       (check-true ((☯ (or eq?
                           equal?
                           (.. = (>< string->number))))
                    "5.0" "5"))
       (check-false ((☯ (or eq?
                            equal?
                            (with-key string->number =)))
                     "5" "6"))
       (check-false ((☯ (or eq?
                            equal?
                            (.. = (>< string->number))))
                     "5" "6"))
       (check-true ((☯ (or _ NOT)) #f) "_ in or"))
     (test-case
         "not (predicate negation)"
       (check-true ((☯ (not positive?)) -5))
       (check-false ((☯ (not positive?)) 5))
       (check-true ((☯ (not _)) #f) "_ in not"))
     (test-case
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
     (test-case
         "juxtaposed boolean combinators"
       (check-true ((☯ (and% positive?
                             (or (> 10)
                                 odd?)))
                    20 5))
       (check-false ((☯ (and% positive?
                              (or (> 10)
                                  even?)))
                     20 5)))
     (test-case
         "juxtaposed conjoin"
       (check-true ((☯ (and% positive? string?))
                    5 "hi"))
       (check-false ((☯ (and% positive? string?))
                     5 5))
       (check-true ((☯ (and% positive? _))
                    5 "hi"))
       (check-true ((☯ (and% _ string?))
                    5 "hi")))
     (test-case
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
     (test-case
         "all"
       (check-true ((☯ (all positive?))
                    3 5))
       (check-false ((☯ (all positive?))
                     3 -5)))
     (test-case
         "any"
       (check-true ((☯ (any positive?))
                    3 5))
       (check-true ((☯ (any positive?))
                    3 -5))
       (check-false ((☯ (any positive?))
                     -3 -5)))
     (test-case
         "none"
       (check-true ((☯ (none positive?))
                    -3 -5))
       (check-false ((☯ (none positive?))
                     3 -5))
       (check-false ((☯ (none positive?))
                     3 5)))
     (test-case
         "all?"
       (check-true ((☯ all?) 3))
       (check-false ((☯ all?) #f))
       (check-true ((☯ all?) 3 5 7))
       (check-false ((☯ all?) 3 #f 5)))
     (test-case
         "any?"
       (check-true ((☯ any?) 3))
       (check-false ((☯ any?) #f))
       (check-true ((☯ any?) 3 5 7))
       (check-true ((☯ any?) 3 #f 5))
       (check-true ((☯ any?) #f #f 5))
       (check-false ((☯ any?) #f #f #f)))
     (test-case
         "none?"
       (check-false ((☯ none?) 3))
       (check-true ((☯ none?) #f))
       (check-false ((☯ none?) 3 5 7))
       (check-false ((☯ none?) 3 #f 5))
       (check-false ((☯ none?) #f #f 5))
       (check-true ((☯ none?) #f #f #f)))
     (test-case
         "gen"
       (check-equal? ((☯ (gen 5)))
                     5)
       (check-equal? ((☯ (gen 5)) 3)
                     5)
       (check-equal? ((☯ (gen 5)) 3 7)
                     5)
       (check-equal? ((☯ (~> (>< (gen 5)) +)) 3 4)
                     10))
     (test-case
         "escape hatch"
       (check-equal? ((☯ (esc (first (list + *)))) 3 7)
                     10
                     "normal racket expressions")
       (check-equal? ((☯ (esc + (second (list + *)))) 3 7)
                     21
                     "multiple expressions in escape clause"))
     (test-suite
      "elementary boolean gates"
      (test-case
          "AND"
        (check-false ((☯ AND) #f))
        (check-true ((☯ AND) 3))
        (check-true ((☯ AND) 3 5 7))
        (check-false ((☯ AND) 3 #f 5))
        (check-false ((☯ AND) #f #f 5))
        (check-false ((☯ AND) #f #f #f)))
      (test-case
          "OR"
        (check-false ((☯ OR) #f))
        (check-true ((☯ OR) 3))
        (check-true ((☯ OR) 3 5 7))
        (check-true ((☯ OR) 3 #f 5))
        (check-true ((☯ OR) #f #f 5))
        (check-false ((☯ OR) #f #f #f)))
      (test-case
          "NOT"
        (check-false ((☯ NOT) 3))
        (check-true ((☯ NOT) #f)))
      (test-case
          "NAND"
        (check-true ((☯ NAND) #f))
        (check-false ((☯ NAND) 3))
        (check-false ((☯ NAND) 3 5 7))
        (check-true ((☯ NAND) 3 #f 5))
        (check-true ((☯ NAND) #f #f 5))
        (check-true ((☯ NAND) #f #f #f)))
      (test-case
          "NOR"
        (check-true ((☯ NOR) #f))
        (check-false ((☯ NOR) 3))
        (check-false ((☯ NOR) 3 5 7))
        (check-false ((☯ NOR) 3 #f 5))
        (check-false ((☯ NOR) #f #f 5))
        (check-true ((☯ NOR) #f #f #f)))
      (test-case
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
      (test-case
          "XNOR"
        (check-true ((☯ XNOR) #f))
        (check-false ((☯ XNOR) 3))
        (check-false ((☯ XNOR) #f 3))
        (check-false ((☯ XNOR) 3 #f))
        (check-true ((☯ XNOR) 3 5))
        (check-true ((☯ XNOR) #f #f))
        (check-true ((☯ XNOR) #f #f #f)))))

    (test-suite
     "routing forms"
     (test-case
         ".."
       (check-equal? ((☯ (.. (string-append "a" _ "b")
                             number->string
                             (* 2)
                             add1))
                      5)
                     "a12b")
       (check-equal? ((☯ (.. (string-append _ "a" _ "b")
                             (>< number->string)
                             (>< add1)))
                      5 6)
                     "6a7b")
       (check-equal? ((☯ (.. +
                             (>< (* 2))
                             (>< add1)))
                      5 6)
                     26)
       (check-equal? ((☯ (.. string-append
                             (>< (string-append "a" _ "b"))))
                      "p" "q")
                     "apbaqb")
       (check-equal? ((☯ (compose (string-append "a" _ "b")
                                  number->string
                                  (* 2)
                                  add1))
                      5)
                     "a12b"
                     "named composition form"))
     (test-case
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
     (test-case
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
     (test-case
         "><"
       (check-equal? ((☯ (~> (>< sqr)
                             +))
                      3 5)
                     34)
       (check-equal? ((☯ (~> (>< _)
                             +))
                      3 5)
                     8
                     "amp with don't-care")
       (check-equal? ((☯ (~> (>< (select))
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
     (test-case
         "allow"
       (check-equal? ((☯ (~> (allow positive?)
                             +))
                      -3 5)
                     5)
       (check-equal? ((☯ (~> (allow positive?)
                             +))
                      -5 -7)
                     0
                     "allow with arity-nullifying clause"))
     (test-case
         "exclude"
       (check-equal? ((☯ (~> (exclude positive?)
                             +))
                      -3 -1 5)
                     -4)
       (check-equal? ((☯ (~> (exclude negative?)
                             +))
                      -5 -7)
                     0
                     "exclude with arity-nullifying clause"))
     (test-case
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
       (check-equal? ((☯ (~> (-< (select))
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
     (test-case
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
       (check-equal? ((☯ (~> (== (select) add1)
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
                  (thunk ((☯ (~> (== (select) add1)
                                 +))
                          5 7 8))
                  "relay elements must be in one-to-one correspondence with input")
       (check-equal? ((☯ (~> (relay sqr add1)
                             +))
                      5 7)
                     33
                     "named relay form"))
     (test-case
         "ground"
       (check-equal? ((☯ (-< ⏚ add1))
                      5)
                     6)
       (check-equal? ((☯ (-< ground add1))
                      5)
                     6)))

    (test-suite
     "partial application"
     (test-case
         "implicitly curried forms"
       (test-case
           "eq?"
         (check-false ((☯ (eq? 5)) 6))
         (check-true ((☯ (eq? 5)) 5)))
       (test-case
           "equal?"
         (check-false ((☯ (equal? "hello")) "bye"))
         (check-true ((☯ (equal? "hello")) "hello")))
       (test-case
           "<"
         (check-false ((☯ (< 5)) 5))
         (check-true ((☯ (< 10)) 5)))
       (test-case
           "<="
         (check-false ((☯ (<= 1)) 5))
         (check-true ((☯ (<= 10)) 5))
         (check-true ((☯ (<= 5)) 5)))
       (test-case
           ">"
         (check-false ((☯ (> 5)) 5))
         (check-true ((☯ (> 1)) 5)))
       (test-case
           ">="
         (check-false ((☯ (>= 10)) 5))
         (check-true ((☯ (>= 1)) 5))
         (check-true ((☯ (>= 5)) 5)))
       (test-case
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
                     "curried foldl"))
     (test-case
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
     (test-case
         "template with multiple arguments"
       (check-true ((☯ (< 1 _ 5 _ 10)) 3 7)
                   "template with multiple arguments")
       (check-false ((☯ (< 1 _ 5 _ 10)) 3 5)
                    "template with multiple arguments")))

    (test-suite
     "high-level circuit elements"
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
      (check-equal? ((☯ (~> (group 2 (select) (select))
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
      (check-equal? ((☯ (~> (sieve negative? (select) (select))
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
      "select"
      (check-equal? ((☯ (select 0))
                     1)
                    1)
      (check-equal? ((☯ (select 1))
                     1 2 3)
                    2)
      (check-equal? ((☯ (select 2))
                     1 2 3)
                    3)
      (check-equal? ((☯ (~> (select 0 2)
                            string-append))
                     "1" "2" "3")
                    "13")
      (check-equal? ((☯ (~> (select 2 0)
                            string-append))
                     "1" "2" "3")
                    "31"))
     (test-suite
      "pass"
      (check-equal? ((☯ (pass positive?))
                     5)
                    5)
      (check-equal? ((☯ (-< (pass negative?) (gen 0)))
                     5)
                    0)
      (check-equal? ((☯ (~> (pass <)
                            +))
                     5 6)
                    11))
     (test-suite
      "if"
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
      "effect"
      (check-equal? ((☯ (ε sub1 add1))
                     5)
                    6)
      (let ([a 10])
        (check-equal? ((☯ (ε (esc (λ (_)
                                    (set! a (add1 a))))
                             add1))
                       5)
                      6)
        (check-equal? a 11)))
     (test-suite
      "collect"
      (check-equal? ((☯ (collect (string-join "")))
                     "a" "b" "c")
                    "abc")
      (check-equal? ((☯ (collect (string-join "")))
                     "a")
                    "a")
      (check-equal? ((☯ (collect (string-join ""))))
                    "")))

    (test-suite
     "arity modulating forms"
     (check-true ((☯ (and% (positive? __) (even? __)))
                  5 6)
                 "and% arity propagation")
     (check-true ((☯ (or% (positive? __) (even? __)))
                  5 6)
                 "or% arity propagation")
     (check-equal? ((☯ (~> (>< (add1 __))
                           +))
                    5 6)
                   13
                   ">< arity propagation")
     (check-equal? ((☯ (~> (== (add1 __) (add1 __))
                           +))
                    5 6)
                   13
                   "== arity propagation")
     (let ([add-two (procedure-reduce-arity + 2)])
       (check-equal? ((☯ (~> (group 2 (add-two __) (add1 __))
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
     (check-equal? ((☯ (~> (allow positive?) +))
                    1 -3 5)
                   6
                   "runtime arity changes in threading form")))

   (test-suite
    "on tests"
    (test-case
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
    (test-case
        "smoke tests"
      (check-equal? (on (2) add1) 3)
      (check-equal? (on (2) (~> sqr add1)) 5)
      (check-equal? (on (2 3) (~> (>< sqr) +)) 13)
      (check-true (on (2) (eq? 2)))
      (check-true (on (2 -3) (and% positive? negative?)))
      (check-equal? (on (2) (if positive? add1 sub1)) 3)))

   (test-suite
    "switch tests"
    (test-case
        "Edge/base cases"
      (check-equal? (switch (6 5)
                            [< 'yo])
                    (void)
                    "no matching clause")
      (check-equal? (switch (5)
                            [positive? 1 2 3])
                    3
                    "more than one body form"))
    (test-case
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
        "call"
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
                    ".. and >< in call position")
      (check-equal? (switch (3 5)
                            [true. (call (~> (>< add1) *))]
                            [else 'no])
                    24)
      (check-equal? (switch (3 5)
                            [true. (call (~> (>< sqr) +))]
                            [else 'no])
                    34)
      (check-equal? (switch (3 5)
                            [true. (call (~> (>< add1) * (-< (/ 2) (/ 3)) +))]
                            [else 'no])
                    20)
      (check-equal? (switch (10 12)
                            [true. (call (~> (== (/ 2) (/ 3)) +))]
                            [else 'no])
                    9)
      (check-equal? (switch (5)
                            [true. (call (~> (fanout 3) +))]
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
                            [(apply > _) (call (apply + _))]
                            [else 'no])
                    6
                    "apply in consequent")
      (check-equal? (switch ((list 2 1 3))
                            [(.. (> 2) length) (call (apply sort < _ #:key identity))]
                            [else 'no])
                    (list 1 2 3)
                    "apply in consequent with non-tail arguments")
      (check-equal? (switch ((list 3 2 1))
                            [(apply > _) (call (map add1 _))]
                            [else 'no])
                    (list 4 3 2)
                    "map in consequent")
      (check-equal? (switch ((list 3 2 1))
                            [(apply > _) (call (filter even? _))]
                            [else 'no])
                    (list 2)
                    "filter in consequent")
      (check-equal? (switch ((list 3 2 1))
                            [(apply > _) (call (foldl + 1 _))]
                            [else 'no])
                    7
                    "foldl in consequent"))
    (test-case
        "connect"
      (check-equal? (switch (5)
                            [positive? (connect [(and integer? odd?) (call add1)]
                                                [else 'positive])]
                            [else 'no])
                    6)
      (check-equal? (switch (6)
                            [positive? (connect [(and integer? odd?) (call add1)]
                                                [else 'positive])]
                            [else 'no])
                    'positive)
      (check-equal? (switch (-5)
                            [positive? (connect [(and integer? odd?) (call add1)]
                                                [else 'positive])]
                            [else 'no])
                    'no)
      (check-equal? (switch (3 5)
                            [< (connect [(~> - abs (< 3)) (call +)])]
                            [else 'no])
                    8
                    "n-ary predicate")
      (check-equal? (switch (3 8)
                            [< (connect [(~> - abs (< 3)) (call +)]
                                        [else 'less])]
                            [else 'no])
                    'less
                    "n-ary predicate")
      (check-equal? (switch (5 3)
                            [< (connect [(~> - abs (< 3)) (call +)]
                                        [else 'less])]
                            [else 'no])
                    'no
                    "n-ary predicate"))
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
                    5)
      (check-equal? (switch ((list 2 1 3))
                            [(apply sort < _ #:key identity) <result>]
                            [else 'no])
                    (list 1 2 3)
                    "apply in predicate with non-tail arguments"))
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
                    'no)))

   (test-suite
    "threading tests"
    (test-case
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
    (test-case
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
    (test-case
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
                    "apply with packed args")))))

(module+ test
  (just-do
   (run-tests tests)))
