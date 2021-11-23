#lang racket/base

(provide measure
         check-value
         check-list
         check-values
         run-benchmark)

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
         version-case
         mischief/shorthand
         (for-syntax racket/base))

(define (measure fn . args)
  (second (values->list (time-apply fn args))))

(define (check-value fn how-many)
  (for ([i (take how-many (cycle (range 10)))])
    (fn i)))

(define (check-list fn how-many)
  (for ([i (in-range how-many)])
    (let ([vs (range i (+ i 10))])
      (fn vs))))

(define (check-values fn how-many)
  (for ([i (in-range how-many)])
    (let ([vs (range i (+ i 10))])
      (call-with-values (λ ()
                          (apply values vs))
                        fn))))

(version-case
 [(version< (version) "7.9.0.22")
  (define-alias define-syntax-parse-rule define-simple-macro)])

(define-syntax-parser run-benchmark
  [(_ name runner ((~datum local) f-name) n-times)
   #'(let ([ms (measure runner f-name n-times)])
       (displayln (~a name ": " ms " ms")))]
  [(_ name runner f-name n-times)
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
   #'(begin (displayln (~a name ":"))
            (for ([f (list f-builtin f-qi)]
                  [label (list "λ" "☯")])
              (let ([ms (measure runner f n-times)])
                (displayln (~a label ": " ms " ms")))))])
