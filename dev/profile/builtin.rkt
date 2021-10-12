#lang racket/base

(provide cond-fn
         compose-fn
         root-mean-square
         fact
         ping)

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

(define (fact n)
  (if (< n 2)
      1
      (* (fact (sub1 n)) n)))

(define (ping n)
  (if (< n 2)
      n
      (+ (ping (sub1 n))
         (ping (- n 2)))))
