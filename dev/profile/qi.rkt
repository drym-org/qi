#lang racket/base

(provide cond-fn
         compose-fn
         root-mean-square)

(require (only-in math sqr)
         qi)

(define-switch cond-fn
  [(< 5) sqr]
  [(> 5) add1]
  [else _])

(define-flow compose-fn
  (~> add1 sqr sub1))

(define-flow root-mean-square
  (~> (map sqr _) (-< (apply + _) length) / sqrt))
