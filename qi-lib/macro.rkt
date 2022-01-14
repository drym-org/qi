#lang racket/base

(provide define-qi-syntax-rule
         define-qi-syntax-parser
         (for-syntax qi-macro
                     qi-macro?
                     qi-macro-transformer))

(require (for-syntax racket/base))

(begin-for-syntax
  (struct qi-macro [transformer]))

(define-syntax-rule (define-qi-syntax-rule (name . pat) template)
  (define-syntax name
    (qi-macro
     (syntax-rules ()
       [(_ . pat) template]))))

(define-syntax-rule (define-qi-syntax-parser name clause ...)
  (define-syntax name
    (qi-macro
     (syntax-rules ()
       clause ...))))
