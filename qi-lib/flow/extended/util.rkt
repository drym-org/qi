#lang racket/base

(provide prettify-flow-syntax)

(require syntax/parse)

;; Partially reconstructs original flow expressions. The chirality
;; is lost and the form is already normalized at this point though!
(define (prettify-flow-syntax stx)
  (syntax-parse stx
    #:datum-literals (#%host-expression
                      esc
                      #%blanket-template
                      #%fine-template
                      thread
                      amp
                      tee
                      relay)
    [(thread
      expr ...)
     #`(~> #,@(map prettify-flow-syntax (syntax->list #'(expr ...))))]
    [((~or #%blanket-template #%fine-template)
      (expr ...))
     (map prettify-flow-syntax (syntax->list #'(expr ...)))]
    [(#%host-expression expr) #'expr]
    [((~datum amp)
      expr ...)
     #`(>< #,@(map prettify-flow-syntax (syntax->list #'(expr ...))))]
    [((~datum tee)
      expr ...)
     #`(-< #,@(map prettify-flow-syntax (syntax->list #'(expr ...))))]
    [((~datum relay)
      expr ...)
     #`(== #,@(map prettify-flow-syntax (syntax->list #'(expr ...))))]
    [(esc expr) (prettify-flow-syntax #'expr)]
    [expr #'expr]))
