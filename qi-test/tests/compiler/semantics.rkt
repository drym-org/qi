#lang racket/base

(provide tests)

(require qi
         rackunit
         rackunit/text-ui
         (only-in math sqr)
         (only-in racket/list range)
         racket/function)

(define tests
  (test-suite
   "Compiler preserves semantics"

   (test-suite
    "deforestation"
    (check-equal? ((☯ (~>> (filter odd?) (map sqr)))
                   (list 1 2 3 4 5))
                  (list 1 9 25))
    (check-exn exn:fail?
               (thunk
                ((☯ (~> (map sqr) (map sqr)))
                 (list 1 2 3 4 5)))
               "(map) doforestation should only be done for right threading")
    (check-exn exn:fail?
               (thunk
                ((☯ (~> (filter odd?) (filter odd?)))
                 (list 1 2 3 4 5)))
               "(filter) doforestation should only be done for right threading")
    (check-exn exn:fail?
               (thunk
                ((☯ (~>> (filter odd?) (~> (foldr + 0))))
                 (list 1 2 3 4 5)))
               "(foldr) doforestation should only be done for right threading")
    (check-equal? ((☯ (~>> values (filter odd?) (map sqr) values))
                   (list 1 2 3 4 5))
                  (list 1 9 25)
                  "optimizes subexpressions")
    (check-equal? ((☯ (~>> (filter odd?) (map sqr) (foldr + 0)))
                   (list 1 2 3 4 5))
                  35)
    (check-equal? ((☯ (~>> (filter odd?) (map sqr) (foldl + 0)))
                   (list 1 2 3 4 5))
                  35)
    (check-equal? ((☯ (~>> (map string-upcase) (foldr string-append "I")))
                   (list "a" "b" "c"))
                  "ABCI")
    (check-equal? ((☯ (~>> (map string-upcase) (foldl string-append "I")))
                   (list "a" "b" "c"))
                  "CBAI")
    (check-equal? ((☯ (~>> (range 10) (map sqr) car)))
                  0)
    (test-suite
     "range (stream producer)"
     ;; Semantic tests of the range producer that cover all combinations:
     (test-equal? "~>>range [1-3] (10)"
                  (~>> (10) range (filter odd?) (map sqr))
                  '(1 9 25 49 81))
     (test-equal? "~>range [1-3] (10)"
                  (~> (10) range (~>> (filter odd?) (map sqr)))
                  '(1 9 25 49 81))
     (test-equal? "~>> range [1-3] (5 10)"
                  (~>> (5 10) range (filter odd?) (map sqr))
                  '(25 49 81))
     (test-equal? "~> range [1-3] (5 10)"
                  (~> (5 10) range (~>> (filter odd?) (map sqr)))
                  '(25 49 81))
     (test-equal? "~>> range [1-3] (5 10 3)"
                  (~>> (5 10 3) range (filter odd?) (map sqr))
                  '(25))
     (test-equal? "~> range [1-3] (5 10 3)"
                  (~> (5 10 3) range (~>> (filter odd?) (map sqr)))
                  '(25))

     (test-equal? "~>> (range 10) [0-2] ()"
                  (~>> () (range 10) (filter odd?) (map sqr))
                  '(1 9 25 49 81))
     (test-equal? "~> (range 10) [0-2] ()"
                  (~> () (range 10) (~>> (filter odd?) (map sqr)))
                  '(1 9 25 49 81))
     (test-equal? "~>> (range 5) [0-2] (10)"
                  (~>> (10) (range 5) (filter odd?) (map sqr))
                  '(25 49 81))
     (test-equal? "~> (range 10) [0-2] (5)"
                  (~> (5) (range 10) (~>> (filter odd?) (map sqr)))
                  '(25 49 81))
     (test-equal? "~>> (range 3) [0-2] (5 10)"
                  (~>> (3) (range 5 10) (filter odd?) (map sqr))
                  '(25))
     (test-equal? "~> (range 5) [0-2] (10 3)"
                  (~> (5) (range 10 3) (~>> (filter odd?) (map sqr)))
                  '(25))

     (test-equal? "~>> (range 5 10) [0-1] ()"
                  (~>> () (range 5 10) (filter odd?) (map sqr))
                  '(25 49 81))
     (test-equal? "~> (range 5 10) [0-1] ()"
                  (~> () (range 5 10) (~>> (filter odd?) (map sqr)))
                  '(25 49 81))
     (test-equal? "~>> (range 5 10) [0-1] (3)"
                  (~>> (3) (range 5 10) (filter odd?) (map sqr))
                  '(25))
     (test-equal? "~> (range 10 3) [0-1] (5)"
                  (~> (5) (range 10 3) (~>> (filter odd?) (map sqr)))
                  '(25))

     (test-equal? "~>> (range 5 10 3) [0] ()"
                  (~>> () (range 5 10 3) (filter odd?) (map sqr))
                  '(25))

     (test-equal? "~>> (range _) [1] (10)"
                  (~>> (10) (range _) (filter odd?) (map sqr))
                  '(1 9 25 49 81))
     (test-equal? "~>> (range _ _) [2] (5 10)"
                  (~>> (5 10) (range _ _) (filter odd?) (map sqr))
                  '(25 49 81))
     (test-equal? "~>> (range _ _ _) [3] (5 10 3)"
                  (~>> (5 10 3) (range _ _ _) (filter odd?) (map sqr))
                  '(25))

     (test-equal? "~>> (range 5 _) [1] (10)"
                  (~>> (10) (range 5 _) (filter odd?) (map sqr))
                  '(25 49 81))
     (test-equal? "~>> (range _ 10) [1] (5)"
                  (~>> (5) (range _ 10) (filter odd?) (map sqr))
                  '(25 49 81))

     (test-equal? "~>> (range 5 _ _) [2] (10 3)"
                  (~>> (10 3) (range 5 _ _) (filter odd?) (map sqr))
                  '(25))
     (test-equal? "~>> (range _ 10 _) [2] (5 3)"
                  (~>> (5 3) (range _ 10 _) (filter odd?) (map sqr))
                  '(25))
     (test-equal? "~>> (range _ _ 3) [2] (5 10)"
                  (~>> (5 10) (range _ _ 3) (filter odd?) (map sqr))
                  '(25))

     (test-equal? "~>> (range 5 10 _) [1] (3)"
                  (~>> (3) (range 5 10 _) (filter odd?) (map sqr))
                  '(25))
     (test-equal? "~>> (range 5 _ 3) [1] (10)"
                  (~>> (10) (range 5 _ 3) (filter odd?) (map sqr))
                  '(25))
     (test-equal? "~>> (range _ 10 3) [1] (5)"
                  (~>> (5) (range _ 10 3) (filter odd?) (map sqr))
                  '(25))))))

(module+ main
  (void (run-tests tests)))
