#lang racket/base

(provide define-qi-syntax-rule
         define-qi-syntax-parser
         (for-syntax qi-macro?
                     qi-macro-transformer))

(require (for-syntax racket/base
                     syntax/parse)
         syntax/parse/define
         syntax/parse)

(begin-for-syntax
  (struct qi-macro [transformer]))

(define-syntax define-qi-syntax-rule
  (syntax-parser
    [(_ (name . pat) template)
     #`(define-syntax #,((make-interned-syntax-introducer 'qi) #'name)
         (qi-macro
          (syntax-parser
            [(_ . pat) #'template])))]))

(define-syntax define-qi-syntax-parser
  (syntax-parser
    [(_ name clause ...)
     #`(define-syntax #,((make-interned-syntax-introducer 'qi) #'name)
         (qi-macro
          (syntax-parser
            clause ...)))]))
