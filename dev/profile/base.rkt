#lang racket/base

(require (only-in data/collection
                  cycle
                  take
                  in)
         (only-in math sqr)
         racket/match
         (only-in racket/list
                  range)
         (prefix-in q: "ionic.rkt")
         (prefix-in b: "builtin.rkt"))

(require racket/function
         racket/format
         "util.rkt")

(define (check-cond cond-fn how-many)
  (for ([i (take how-many (in (cycle '(1 2 3))))])
    (cond-fn i)))

(define (check-compose compose-fn how-many)
  (for ([v (in-range how-many)])
    (compose-fn v)))

(define (check-rms rms how-many)
  (for ([i (in-range how-many)])
    (let ([vs (range i (+ i 10))])
      (rms vs))))

(displayln "Conditionals benchmark...")
(for ([f (list b:cond-fn q:cond-fn)]
      [name (list "Built-in:" "Qi:")])
  (let ([ms (measure check-cond f 300000)])
    (displayln (~a name ": " ms " ms"))))

(displayln "Composition benchmark...")
(for ([f (list b:compose-fn q:compose-fn)]
      [name (list "Built-in" "Qi")])
  (let ([ms (measure check-compose f 3000000)])
    (displayln (~a name ": " ms " ms"))))

(displayln "Root Mean Square benchmark...")
(for ([f (list b:root-mean-square q:root-mean-square)]
      [name (list "Built-in:" "Qi:")])
  (let ([ms (measure check-rms f 300000)])
    (displayln (~a name ": " ms " ms"))))
