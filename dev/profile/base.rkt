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

(define (check-value fn how-many)
  (for ([i (take how-many (cycle (range 10)))])
    (fn i)))

(define (check-list fn how-many)
  (for ([i (in-range how-many)])
    (let ([vs (range i (+ i 10))])
      (fn vs))))

(define-syntax-parse-rule (run-benchmark name
                                         runner
                                         f-name
                                         n-times)
  #:with f-builtin (datum->syntax #'name
                                  (string->symbol
                                   (string-append "b:"
                                                  (symbol->string
                                                   (syntax->datum #'f-name)))))
  #:with f-qi (datum->syntax #'name
                             (string->symbol
                              (string-append "q:"
                                             (symbol->string
                                              (syntax->datum #'f-name)))))
  (begin (displayln (~a "Running " name " benchmark..."))
         (for ([f (list f-builtin f-qi)]
               [label (list "λ" "☯")])
           (let ([ms (measure runner f n-times)])
             (displayln (~a label ": " ms " ms"))))))

(run-benchmark "Conditionals"
               check-value
               cond-fn
               300000)

(run-benchmark "Composition"
               check-value
               compose-fn
               300000)

(run-benchmark "Root Mean Square"
               check-list
               root-mean-square
               500000)
