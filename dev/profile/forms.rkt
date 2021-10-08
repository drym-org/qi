#lang racket/base

(require (only-in data/collection
                  cycle
                  take
                  in)
         (only-in math sqr)
         racket/match
         qi
         racket/format)

(require "util.rkt")

(define (group a b c)
  ((☯ (~> (group 2 + values)
          (group 2 + values)))
   a b c))

(define (check-group how-many)
  (for ([vs (take how-many (in (cycle (list (list 3 4 5)
                                            (list 4 5 6)
                                            (list 5 6 7)))))])
    (match-let ([(list a b c) vs])
      (group a b c))))

(define (relay a b c)
  ((☯ (== add1
          sub1
          sqr))
   a b c))

(define (check-relay how-many)
  (for ([vs (take how-many (in (cycle (list (list 3 4 5)
                                            (list 4 5 6)
                                            (list 5 6 7)))))])
    (match-let ([(list a b c) vs])
      (relay a b c))))

(let ([ms (measure check-group 100000)])
  (displayln (~a "group: " ms " ms")))

(let ([ms (measure check-relay 100000)])
  (displayln (~a "relay: " ms " ms")))
