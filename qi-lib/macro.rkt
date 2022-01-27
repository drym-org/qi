#lang racket/base

(provide define-qi-syntax-rule
         define-qi-syntax-parser
         (for-syntax qi-macro
                     qi-macro?
                     qi-macro-transformer))

(require (for-syntax racket/base
                     syntax/parse)
         syntax/parse/define
         syntax/parse
         version-case)

(begin-for-syntax
  (struct qi-macro [transformer]))

;; Use binding spaces for macros on newer versions of Racket
(version-case
 [(version< (version) "8.2.0.3")

  (define-syntax-parse-rule (define-qi-syntax-rule (name . pat) template)
    (define-syntax name
      (qi-macro
       (syntax-parser
         [(_ . pat) #'template]))))

  (define-syntax-parse-rule (define-qi-syntax-parser name clause ...)
    (define-syntax name
      (qi-macro
       (syntax-parser
         clause ...))))]
 [else
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
              clause ...)))]))])
