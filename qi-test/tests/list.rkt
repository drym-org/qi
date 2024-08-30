#lang racket/base

(provide tests)

(require qi
         qi/list
         rackunit
         rackunit/text-ui
         syntax/macro-testing
         (only-in racket/function thunk)
         (only-in racket/string non-empty-string?)
         (only-in math sqr))

(define tests
  (test-suite
   "qi/list tests"

   (test-suite
    "basic"

    (test-suite
     "stream producers"
     (test-suite
      "range"
      (test-equal? "single arg"
                   ((☯ (range 3)))
                   (list 0 1 2))
      (test-equal? "two args"
                   ((☯ (range 1 4)))
                   (list 1 2 3))
      (test-equal? "three args"
                   ((☯ (range 1 6 2)))
                   (list 1 3 5))
      (test-exn "expects at least one argument"
                exn:fail:syntax?
                (thunk
                 (convert-compile-time-error
                  ((☯ range)))))))

    (test-suite
     "stream transformers"
     (test-suite
      "filter"
      (test-equal? "simple list"
                   ((☯ (filter odd?))
                    (list 1 2 3))
                   (list 1 3))
      (test-equal? "empty list"
                   ((☯ (filter odd?))
                    null)
                   null)
      (test-equal? "no matching values"
                   ((☯ (filter odd?))
                    (list 2 4 6))
                   null)
      (test-equal? "all matching values"
                   ((☯ (filter odd?))
                    (list 1 3 5))
                   (list 1 3 5))
      (test-equal? "filter with higher-order Qi syntax"
                   ((☯ (filter (and positive? integer?)))
                    (list 1 -2 3 0.2 4))
                   (list 1 3 4)))
     (test-suite
      "map"
      (test-equal? "simple list"
                   ((☯ (map sqr))
                    (list 1 2 3))
                   (list 1 4 9))
      (test-equal? "empty list"
                   ((☯ (map sqr))
                    null)
                   null)
      (test-equal? "map with higher-order Qi syntax"
                   ((☯ (map (~> sqr add1)))
                    (list 1 2 3))
                   (list 2 5 10)))
     (test-suite
      "filter-map"
      (test-equal? "simple list"
                   ((☯ (filter-map (if positive? sqr #false)))
                    (list 1 -2 3))
                   (list 1 9))
      (test-equal? "empty list"
                   ((☯ (filter-map (if positive? sqr #false)))
                    null)
                   null))
     (test-suite
      "take (stateful transformer)"
      (test-equal? "simple list"
                   ((☯ (take 2))
                    (list 1 2 3))
                   (list 1 2))
      (test-equal? "take none"
                   ((☯ (take 0))
                    (list 1 2 3))
                   null)
      (test-exn "empty list"
                exn:fail:contract?
                (thunk ((☯ (take 2))
                        null)))
      (test-equal? "take none from empty list"
                   ((☯ (take 0))
                    null)
                   null)))

    (test-suite
     "stream consumers"
     (test-suite
      "foldl"
      (test-equal? "simple list"
                   ((☯ (foldl + 0))
                    (list 1 2 3))
                   6)
      (test-equal? "empty list"
                   ((☯ (foldl + 0))
                    null)
                   0)
      (test-equal? "non-commutative operation"
                   ((☯ (foldl string-append ""))
                    (list "a" "b" "c"))
                   "cba")
      (test-equal? "foldl with higher-order Qi syntax"
                   ((☯ (foldl (~> (>< number->string)
                                  string-append
                                  string->number)
                              0))
                    (list 1 2 3))
                   3210))
     (test-suite
      "foldr"
      (test-equal? "simple list"
                   ((☯ (foldr + 0))
                    (list 1 2 3))
                   6)
      (test-equal? "empty list"
                   ((☯ (foldr + 0))
                    null)
                   0)
      (test-equal? "non-commutative operation"
                   ((☯ (foldr string-append ""))
                    (list "a" "b" "c"))
                   "abc")
      (test-equal? "foldr with higher-order Qi syntax"
                   ((☯ (foldr (~> (>< number->string)
                                  string-append
                                  string->number)
                              0))
                    (list 1 2 3))
                   1230))
     (test-suite
      "car"
      (test-equal? "simple list"
                   ((☯ car)
                    (list 1 2 3))
                   1)
      (test-exn "empty list"
                exn:fail:contract?
                (thunk ((☯ car)
                        null))))
     (test-suite
      "null?"
      (test-false "simple list"
                  ((☯ null?)
                   (list 1 2 3)))
      (test-true "empty list"
                 ((☯ null?)
                  null)))
     (test-suite
      "empty?"
      (test-false "simple list"
                  ((☯ empty?)
                   (list 1 2 3)))
      (test-true "empty list"
                 ((☯ empty?)
                  null)))
     (test-suite
      "length"
      (test-equal? "simple list"
                   ((☯ length)
                    (list 1 2 3))
                   3)
      (test-equal? "empty list"
                   ((☯ length)
                    null)
                   0))
     (test-suite
      "list-ref"
      (test-equal? "simple list"
                   ((☯ (list-ref 1))
                    (list 1 2 3))
                   2)
      (test-exn "empty list"
                exn:fail:contract?
                (thunk ((☯ (list-ref 1))
                        null))))
     (test-suite
      "cadr"
      (test-equal? "simple list"
                   ((☯ cadr)
                    (list 1 2 3))
                   2)
      (test-exn "empty list"
                exn:fail:contract?
                (thunk ((☯ cadr)
                        null))))
     (test-suite
      "caddr"
      (test-equal? "simple list"
                   ((☯ caddr)
                    (list 1 2 3))
                   3)
      (test-exn "empty list"
                exn:fail:contract?
                (thunk ((☯ caddr)
                        null))))
     (test-suite
      "cadddr"
      (test-equal? "simple list"
                   ((☯ cadddr)
                    (list 1 2 3 4))
                   4)
      (test-exn "empty list"
                exn:fail:contract?
                (thunk ((☯ cadddr)
                        null))))))

   (test-suite
    "combinations"

    (test-equal? "filter..map"
                 ((☯ (~> (filter odd?)
                         (map sqr)))
                  (list 1 2 3))
                 (list 1 9))
    (test-equal? "filter..car"
                 ((☯ (~> (filter odd?)
                         car))
                  (list 1 2 3))
                 1)
    (test-equal? "filter..foldl"
                 ((☯ (~> (filter odd?)
                         (foldl + 0)))
                  (list 1 2 3))
                 4)
    (test-equal? "filter..foldr"
                 ((☯ (~> (filter odd?)
                         (foldr + 0)))
                  (list 1 2 3))
                 4)
    (test-equal? "filter..foldl with non-commutative operation"
                 ((☯ (~> (filter non-empty-string?)
                         (foldl string-append "")))
                  (list "a" "b" "c"))
                 "cba")
    (test-equal? "filter..foldr with non-commutative operation"
                 ((☯ (~> (filter non-empty-string?)
                         (foldr string-append "")))
                  (list "a" "b" "c"))
                 "abc")
    (test-equal? "map..foldl"
                 ((☯ (~> (map string-upcase)
                         (foldl string-append "I")))
                  (list "a" "b" "c"))
                 "CBAI")
    (test-equal? "map..foldr"
                 ((☯ (~> (map string-upcase)
                         (foldr string-append "I")))
                  (list "a" "b" "c"))
                 "ABCI")
    (test-equal? "range..car"
                 ((☯ (~> (range 10)
                         car)))
                 0)
    (test-equal? "range..map"
                 ((☯ (~> (range 3)
                         (map sqr))))
                 (list 0 1 4))
    (test-equal? "range..filter..car"
                 ((☯ (~> (range 1 4)
                         (filter odd?)
                         car)))
                 1)
    (test-equal? "range..map..car"
                 ((☯ (~> (range 10)
                         (map sqr)
                         car)))
                 0)
    (test-equal? "filter..map..foldr"
                 ((☯ (~> (filter odd?)
                         (map sqr)
                         (foldr + 0)))
                  (list 1 2 3 4 5))
                 35)
    (test-equal? "filter..map..foldl"
                 ((☯ (~> (filter odd?)
                         (map sqr)
                         (foldl + 0)))
                  (list 1 2 3 4 5))
                 35)
    (test-equal? "range..filter..map"
                 ((☯ (~> (range 10)
                         (filter odd?)
                         (map sqr))))
                 '(1 9 25 49 81))
    (test-equal? "range..filter..map with right threading"
                 ((☯ (~>> (range 10)
                          (filter odd?)
                          (map sqr))))
                 '(1 9 25 49 81))
    (test-equal? "range..filter..map with different nested threading direction"
                 ((☯ (~> (range 10)
                         (~>> (filter odd?)
                              (map sqr)))))
                 '(1 9 25 49 81))
    (test-equal? "take after filter"
                 ((☯ (~> (range 20)
                         (filter odd?)
                         (take 5)
                         (map sqr))))
                 '(1 9 25 49 81))
    (test-equal? "two takes after filter"
                 ((☯ (~> (range 20)
                         (filter odd?)
                         (take 5)
                         (take 3)
                         (map sqr))))
                 '(1 9 25)))))

(module+ main
  (void
   (run-tests tests)))
