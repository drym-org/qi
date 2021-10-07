#lang racket/base

(provide cond-fn
         compose-fn
         root-mean-square)

(require (only-in math sqr)
         ionic)

(define-switch (cond-fn x)
  [(< 5) 'a]
  [(> 5) 'b]
  [else 'c])

(define (compose-fn f g)
  ((☯ (~> g f)) 5))

(define-flow (root-mean-square vs)
  (~>> (map sqr) (-< (apply + _) length) / sqrt))
