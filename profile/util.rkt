#lang racket/base

(provide measure
         check-value
         check-list
         check-values
         check-two-values
         run-benchmark
         run-competitive-benchmark)

(require (only-in racket/list
                  range
                  second)
         (only-in adjutor
                  values->list)
         (only-in data/collection
                  cycle
                  take
                  in)
         racket/function
         racket/format
         syntax/parse/define
         (for-syntax racket/base))

(define (measure fn . args)
  (second (values->list (time-apply fn args))))

(define (check-value fn how-many [inputs (range 10)])
  ;; call a function with a single (numeric) argument
  (for ([i (take how-many (cycle inputs))])
    (fn i)))

(define (check-list fn how-many)
  ;; call a function with a single list argument
  (for ([i (in-range how-many)])
    (let ([vs (range i (+ i 10))])
      (fn vs))))

(define (check-values fn how-many)
  ;; call a function with multiple values as independent arguments
  (for ([i (in-range how-many)])
    (let ([vs (range i (+ i 10))])
      (call-with-values (λ ()
                          (apply values vs))
                        fn))))

(define (check-two-values fn how-many)
  ;; call a function with two values as arguments
  (for ([i (in-range how-many)])
    (let ([vs (range i (+ i 2))])
      (call-with-values (λ ()
                          (apply values vs))
                        fn))))

(define-syntax-parse-rule (run-benchmark f-name runner n-times)
  #:with name (datum->syntax #'f-name
                (symbol->string
                 (syntax->datum #'f-name)))
  (let ([ms (measure runner f-name n-times)])
    (displayln (~a name ": " ms " ms"))))

(define-syntax-parse-rule (run-competitive-benchmark name runner f-name n-times)
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
  (begin
    (displayln (~a name ":"))
    (for ([f (list f-builtin f-qi)]
          [label (list "λ" "☯")])
      (let ([ms (measure runner f n-times)])
        (displayln (~a label ": " ms " ms"))))))
