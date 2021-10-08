#lang racket/base

(provide cond-fn
         compose-fn
         root-mean-square)

(require (only-in math sqr))

(define (cond-fn x)
  (cond [(< x 5) (sqr x)]
        [(> x 5) (add1 x)]
        [else x]))

(define (compose-fn v)
  ((compose sub1 sqr add1) v))

(define (root-mean-square vs)
  (let ([squares (map sqr vs)])
    (let ([mean-squares (/ (apply + squares)
                           (length squares))])
      (sqrt mean-squares))))
