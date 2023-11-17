#lang racket/base

(provide conditionals
         composition
         root-mean-square
         factorial
         pingala
         eratosthenes
         collatz
         range-map
         filter-map
         filter-map-foldr
         filter-map-foldl
         filter-map-values
         range-map-sum
         double-list
         double-values)

(require (only-in math sqr)
         racket/list
         racket/match)

(define (conditionals x)
  (cond [(< x 5) (sqr x)]
        [(> x 5) (add1 x)]
        [else x]))

(define (composition v)
  (sub1 (sqr (add1 v))))

(define (root-mean-square vs)
  (sqrt (/ (apply + (map sqr vs))
           (length vs))))

(define (factorial n)
  (if (< n 2)
      1
      (* (factorial (sub1 n)) n)))

(define (pingala n)
  (if (< n 2)
      n
      (+ (pingala (sub1 n))
         (pingala (- n 2)))))

(define (eratosthenes n)
  (let ([lst (range 2 (add1 n))])
    (let loop ([rem lst]
               [result null])
      (match rem
        ['() (reverse result)]
        [(cons v vs) (loop (filter (λ (n)
                                     (not (= 0 (remainder n v))))
                                   vs)
                           (cons v result))]))))

(define (collatz n)
  (cond [(<= n 1) (list n)]
        [(odd? n) (cons n (collatz (+ (* 3 n) 1)))]
        [(even? n) (cons n (collatz (quotient n 2)))]))

(define (range-map v)
  (map sqr (range 0 v)))

(define (filter-map lst)
  (map sqr (filter odd? lst)))

(define (filter-map-foldr lst)
  (foldr + 0 (map sqr (filter odd? lst))))

(define (filter-map-foldl lst)
  (foldl + 0 (map sqr (filter odd? lst))))

(define (filter-map-values . vs)
  (apply values
         (map sqr (filter odd? vs))))

(define (~sum vs)
  (apply + vs))

(define (range-map-sum n)
  (~sum (map sqr (range 1 n))))

(define (double-list lst)
  (apply append (map (λ (v) (list v v)) lst)))

(define (double-values . vs)
  (apply values
         (apply append (map (λ (v) (list v v)) vs))))
