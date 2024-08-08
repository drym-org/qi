#lang racket/base

(provide tests)

(require qi
         qi/list
         rackunit
         rackunit/text-ui
         (only-in racket/function thunk)
         (only-in math sqr))

(define tests
  (test-suite
   "qi/list tests"

   (test-suite
    "basic"
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
                  (list 1 3 5)))
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
                  (list 1 3 5)))
    (test-suite
     "map"
     (test-equal? "simple list"
                  ((☯ (map sqr))
                   (list 1 2 3))
                  (list 1 4 9))
     (test-equal? "empty list"
                  ((☯ (map sqr))
                   null)
                  null))
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
                  "cba"))
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
                  "abc"))
    (test-suite
     "car"
     (test-equal? "simple list"
                  ((☯ car)
                   (list 1 2 3))
                  1)
     (test-exn "empty list"
               exn:fail:contract?
               (thunk ((☯ car)
                       null)))
     (test-equal? "non-commutative operation"
                  ((☯ (foldr string-append ""))
                   (list "a" "b" "c"))
                  "abc"))
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
     "take"
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
                  null))
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
     "caddr"
     (test-equal? "simple list"
                  ((☯ cadddr)
                   (list 1 2 3 4))
                  4)
     (test-exn "empty list"
               exn:fail:contract?
               (thunk ((☯ cadddr)
                       null)))))))

(module+ main
  (void
   (run-tests tests)))
