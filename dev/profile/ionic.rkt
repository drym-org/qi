#lang racket/base

(provide cond-fn
         compose-fn
         root-mean-square)

(require (only-in math sqr)
         ionic)

(define-switch cond-fn
  [(< 5) 'a]
  [(> 5) 'b]
  [else 'c])

(define-flow compose-fn
  (~> add1 sqr sub1))

(define-flow root-mean-square
  (~>> (map sqr) (-< (apply + _) length) / sqrt))
