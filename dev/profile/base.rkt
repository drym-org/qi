#lang racket/base

(require (only-in data/collection
                  cycle
                  take
                  in)
         (only-in math sqr)
         racket/match
         (only-in racket/list
                  range)
         (prefix-in q: "qi.rkt")
         (prefix-in b: "builtin.rkt")
         syntax/parse/define
         version-case
         mischief/shorthand
         (for-syntax racket/base))

(require racket/function
         racket/format
         "util.rkt")

(version-case
 [(version< (version) "7.9.0.22")
  (define-alias define-syntax-parse-rule define-simple-macro)])

(define (check-cond cond-fn how-many)
  (for ([i (take how-many (cycle (range 10)))])
    (cond-fn i)))

(define (check-compose compose-fn how-many)
  (for ([v (in-range how-many)])
    (compose-fn v)))

(define (check-rms rms how-many)
  (for ([i (in-range how-many)])
    (let ([vs (range i (+ i 10))])
      (rms vs))))

(define-syntax-parse-rule (run-benchmark name
                                         runner
                                         f-builtin
                                         f-qi
                                         n-times)
  (begin (displayln (~a "Running " name " benchmark..."))
         (for ([f (list f-builtin f-qi)]
               [label (list "λ" "☯")])
           (let ([ms (measure runner f n-times)])
             (displayln (~a label ": " ms " ms"))))))

(run-benchmark "Conditionals"
               check-cond
               b:cond-fn
               q:cond-fn
               300000)

(run-benchmark "Composition"
               check-compose
               b:compose-fn
               q:compose-fn
               3000000)

(run-benchmark "Root Mean Square"
               check-rms
               b:root-mean-square
               q:root-mean-square
               500000)
