#lang racket/base

(provide conditionals
         composition
         root-mean-square
         factorial
         pingala
         eratosthenes
         collatz
         range-map-car
         filter-map
         filter-map-foldr
         filter-map-foldl
         long-functional-pipeline
         filter-map-values
         range-map-sum
         double-list
         double-values)

(require (only-in math sqr)
         (only-in racket/list range)
         qi)

(define-switch conditionals
  [(< 5) sqr]
  [(> 5) add1]
  [else _])

(define-flow composition
  (~> add1 sqr sub1))

(define-flow root-mean-square
  (~> (-< (~>> △ (>< sqr) +)
          length) / sqrt))

(define-switch factorial
  [(< 2) 1]
  [else (~> (-< _ (~> sub1 factorial)) *)])

(define-switch pingala
  [(< 2) _]
  [else (~> (-< sub1
                (- 2)) (>< pingala) +)])

(define-flow (eratosthenes n)
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


;; (define-flow filter-map
;;   (~> △ (>< (if odd? sqr ⏚)) ▽))

(define-flow filter-map
  (~>> (filter odd?)
       (map sqr)))

(define-flow filter-map-foldr
  (~>> (filter odd?)
       (map sqr)
       (foldr + 0)))

(define-flow filter-map-foldl
  (~>> (filter odd?)
       (map sqr)
       (foldl + 0)))

(define-flow range-map-car
  (~>> (range 0)
       (map sqr)
       car))

(define-flow range-map-sum
  ;; TODO: this should be written as (apply +)
  ;; and that should be normalized to (foldr/l + 0)
  ;; (depending on which of foldl/foldr is more performant)
  (~>> (range 0) (map sqr) (foldr + 0)))

(define-flow long-functional-pipeline
  (~>> (range 0)
       (filter odd?)
       (map sqr)
       values
       (filter (λ (v) (< (remainder v 10) 5)))
       (map (λ (v) (* 2 v)))
       (foldl + 0)))

;; (define filter-double
;;   (map (☯ (when odd?
;;             (-< _ _)))
;;        (list 1 2 3 4 5)))

(define-flow filter-map-values
  (>< (if odd? sqr ⏚)))

(define-flow double-list
  (~> △ (>< (-< _ _)) ▽))

(define-flow double-values
  (>< (-< _ _)))
