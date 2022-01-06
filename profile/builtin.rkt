#lang racket/base

(provide cond-fn
         compose-fn
         root-mean-square
         fact
         ping
         eratos
         filter-map-fn
         filter-map-values
         double-list
         double-values)

(require (only-in math sqr)
         racket/list
         racket/match)

(define (cond-fn x)
  (cond [(< x 5) (sqr x)]
        [(> x 5) (add1 x)]
        [else x]))

(define (compose-fn v)
  ((compose sub1 sqr add1) v))

(define (root-mean-square vs)
  (sqrt (/ (apply + (map sqr vs))
           (length vs))))

(define (fact n)
  (if (< n 2)
      1
      (* (fact (sub1 n)) n)))

(define (ping n)
  (if (< n 2)
      n
      (+ (ping (sub1 n))
         (ping (- n 2)))))

(define (eratos n)
  (let ([lst (range 2 (add1 n))])
    (let loop ([rem lst]
               [result null])
      (match rem
        ['() (reverse result)]
        [(cons v vs) (loop (filter (λ (n)
                                     (not (= 0 (remainder n v))))
                                   vs)
                           (cons v result))]))))

(define (filter-map-fn lst)
  (map sqr (filter odd? lst)))

(define (filter-map-values . vs)
  (apply values
         (map sqr (filter odd? vs))))

(define (double-list lst)
  (apply append (map (λ (v) (list v v)) lst)))

(define (double-values . vs)
  (apply values
         (apply append (map (λ (v) (list v v)) vs))))
