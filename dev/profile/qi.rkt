#lang racket/base

(provide cond-fn
         compose-fn
         root-mean-square
         fact
         ping
         filter-map-fn
         filter-map-values
         double-list
         double-values)

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

(define-switch fact
  [(< 2) 1]
  [else (~> (-< _ (~> sub1 fact)) *)])

(define-switch ping
  [(< 2) _]
  [else (~> (-< sub1
                (- 2)) (>< ping) +)])

(define-flow filter-map-fn
  (~> △ (>< (if odd? sqr ⏚)) ▽))

(define-flow filter-map-values
  (>< (if odd? sqr ⏚)))

(define-flow double-list
  (~> △ (>< (-< _ _)) ▽))

(define-flow double-values
  (>< (-< _ _)))
