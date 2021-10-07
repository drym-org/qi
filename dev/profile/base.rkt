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
  (for ([fns (take how-many (in (cycle (list (list add1 sqr)
                                             (list sub1 sqr)
                                             (list add1 sub1)))))])
    (match-let ([(list f g) fns])
      (compose-fn f g))))

(define (check-rms rms how-many)
  (for ([i (in-range how-many)])
    (let ([vs (range i (+ i 10))])
      (rms vs))))

(display "\n")
(displayln "Conditionals benchmark...")
(for ([f (list b:cond-fn q:cond-fn)]
      [name (list "Built-in:" "Qi:")])
  (let ([ms (measure check-cond f 300000)])
    (displayln (~a name ": " ms " ms"))))

(display "\n")
(displayln "Composition benchmark...")
(for ([f (list b:compose-fn q:compose-fn)]
      [name (list "Built-in" "Qi")])
  (let ([ms (measure check-compose f 300000)])
    (displayln (~a name ": " ms " ms"))))

(display "\n")
(displayln "Root Mean Square benchmark...")
(for ([f (list b:root-mean-square q:root-mean-square)]
      [name (list "Built-in:" "Qi:")])
  (let ([ms (measure check-rms f 100000)])
    (displayln (~a name ": " ms " ms"))))
