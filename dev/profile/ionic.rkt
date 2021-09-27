#lang racket/base

(require (only-in data/collection
                  cycle
                  take
                  in)
         (only-in math sqr)
         racket/match
         ionic)

(define-switch (cond-fn x)
  [(< 5) 'a]
  [(> 5) 'b]
  [else 'c])

(define (check-cond how-many)
  (for ([i (take how-many (in (cycle '(1 2 3))))])
    (cond-fn i)))

(define (compose-fn f g)
  ((☯ (~> g f)) 5))

(define (check-compose how-many)
  (for ([fns (take how-many (in (cycle (list (list add1 sqr)
                                             (list sub1 sqr)
                                             (list add1 sub1)))))])
    (match-let ([(list f g) fns])
      (compose-fn f g))))

(check-cond 100000)
(check-compose 100000)
