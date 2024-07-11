#lang racket/base

(provide report-syntax-error
         define-alias
         (for-syntax params-parser))

(require racket/string
         racket/format
         racket/match
         syntax/parse/define
         (for-syntax racket/base
                     syntax/parse/lib/function-header))

(define (report-syntax-error stx usage . msgs)
  (match (syntax->datum stx)
    [(cons name args)
     (raise-syntax-error name
                         (~a "Syntax error in "
                             (list* name args)
                             "\n"
                             "Usage:\n"
                             "  " usage
                             (if (null? msgs)
                                 ""
                                 (string-append "\n"
                                                (string-join msgs "\n"))))
                         stx)]
    [name
     (raise-syntax-error name
                         (~a "Syntax error in "
                             name
                             "\n"
                             "Usage:\n"
                             "  " usage
                             (if (null? msgs)
                                 ""
                                 (string-append "\n"
                                                (string-join msgs "\n"))))
                         stx)]))

(define-syntax-parse-rule (define-alias alias:id name:id)
  (define-syntax alias (make-rename-transformer #'name)))

(begin-for-syntax
  (define (params-parser stx)
    (syntax-parse stx
      [((~or* 1st:id [1st:id _]) . rest:formals)
       #`(1st . #,(params-parser #'rest))]
      [(_:keyword _ . rest:formals)
       (params-parser #'rest)]
      [() stx]
      [_:id #`(#,stx)])))
