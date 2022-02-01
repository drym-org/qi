#lang racket/base

(provide define-qi-syntax-rule
         define-qi-syntax-parser
         (for-syntax qi-macro?
                     qi-macro-transformer))

(require (for-syntax racket/base
                     syntax/parse
                     version-case)
         (for-meta 2
                   version-case
                   racket/base)
         syntax/parse/define
         syntax/parse
         version-case)

(begin-for-syntax
  (version-case
   [(version< (version) "8.2.0.3")
    (define-values (prop:qi-macro qi-macro? qi-macro-transformer)
      (make-struct-type-property 'qi-macro))]
   [else
    (struct qi-macro [transformer])]))

;; Use binding spaces for macros on newer versions of Racket
(version-case
 [(version< (version) "8.2.0.3")

  (define-syntax-parse-rule (define-qi-syntax-rule (name . pat) template)
    (begin
      (begin-for-syntax
        (struct qi-macro-struct []
          #:property prop:qi-macro
          (syntax-parser
            [(_ . pat) #'template])
          #:property prop:procedure
          (λ args
            (syntax-parse (cadr args)
              [(_ . pat) #'template]))))
      (define-syntax name
        (qi-macro-struct))))

  (define-syntax-parse-rule (define-qi-syntax-parser name clause ...)
    (begin
      (begin-for-syntax
        (struct qi-macro-struct []
          #:property prop:qi-macro
          (syntax-parser
            clause ...)
          #:property prop:procedure
          (λ args
            (syntax-parse (cadr args)
              clause ...))))
      (define-syntax name
        (qi-macro-struct))))]
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
