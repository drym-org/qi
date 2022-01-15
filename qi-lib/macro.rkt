#lang racket/base

(provide define-qi-syntax-rule
         define-qi-syntax-parser
         (for-syntax qi-macro
                     qi-macro?
                     qi-macro-transformer))

(require (for-syntax racket/base
                     syntax/parse)
         syntax/parse/define
         syntax/parse)

(begin-for-syntax
  (struct qi-macro [transformer]))

(define-syntax-parse-rule (define-qi-syntax-rule (name . pat) template)
  (define-syntax name
    (qi-macro
     (syntax-parser
       [(_ . pat) #'template]))))

(define-syntax-parse-rule (define-qi-syntax-parser name clause ...)
  (define-syntax name
    (qi-macro
     (syntax-parser
       clause ...))))
