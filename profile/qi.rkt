#lang racket/base

(provide cond-fn
         compose-fn
         root-mean-square
         fact
         ping
         eratos
         collatz
         filter-map-fn
         filter-map-values
         double-list
         double-values)

(require (only-in math sqr)
         (only-in racket/list range)
         qi)

(define-switch cond-fn
  [(< 5) sqr]
  [(> 5) add1]
  [else _])

(define-flow compose-fn
  (~> add1 sqr sub1))

(define-flow root-mean-square
  (~> (-< (~>> △ (>< sqr) +)
          length) / sqrt))

(define-switch fact
  [(< 2) 1]
  [else (~> (-< _ (~> sub1 fact)) *)])

(define-switch ping
  [(< 2) _]
  [else (~> (-< sub1
                (- 2)) (>< ping) +)])

(define-flow (eratos n)
  (~> (-< (gen null) (~>> add1 (range 2) △))
      (feedback (while (~> (block 1) live?))
                (then (~> 1> reverse))
                (-< (~> (select 1 2) X cons)
                    (~> (-< (~>> 2> (clos (~> remainder (not (= 0)))))
                            (block 1 2)) pass)))))

(define-flow collatz
  (switch
    [(<= 1) list]
    [odd? (~> (-< _ (~> (* 3) (+ 1) collatz))
              cons)]
    [even? (~> (-< _ (~> (quotient 2) collatz))
               cons)]))


(define-flow filter-map-fn
  (~> △ (>< (if odd? sqr ⏚)) ▽))

(define-flow filter-map-values
  (>< (if odd? sqr ⏚)))

(define-flow double-list
  (~> △ (>< (-< _ _)) ▽))

(define-flow double-values
  (>< (-< _ _)))
