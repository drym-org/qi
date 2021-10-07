#lang racket/base

(provide cond-fn
         compose-fn
         root-mean-square)

(require (only-in math sqr))

(define (cond-fn x)
  (cond [(< x 5) 'a]
        [(> x 5) 'b]
        [else 'c]))

(define (compose-fn f g)
  ((compose f g) 5))

(define (root-mean-square vs)
  (let ([squares (map sqr vs)])
    (let ([mean-squares (/ (apply + squares)
                           (length squares))])
      (sqrt mean-squares))))
