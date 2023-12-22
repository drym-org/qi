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
                      relay
                      gen
                      pass
                      sep
                      and
                      or
                      not
                      all
                      any
                      fanout
                      group
                      if
                      sieve
                      partition
                      try
                      >>
                      <<
                      feedback
                      loop
                      loop2
                      clos)
    [(thread
      expr ...)
     #`(~> #,@(map prettify-flow-syntax (syntax->list #'(expr ...))))]
    [((~or #%blanket-template #%fine-template)
      (expr ...))
     (map prettify-flow-syntax (syntax->list #'(expr ...)))]
    [(#%host-expression expr) #'expr]
    [(amp
      expr ...)
     #`(>< #,@(map prettify-flow-syntax (syntax->list #'(expr ...))))]
    [(tee
      expr ...)
     #`(-< #,@(map prettify-flow-syntax (syntax->list #'(expr ...))))]
    [(relay
      expr ...)
     #`(== #,@(map prettify-flow-syntax (syntax->list #'(expr ...))))]
    [(gen
      expr ...)
     #`(gen #,@(map prettify-flow-syntax (syntax->list #'(expr ...))))]
    [(pass
      expr ...)
     #`(pass #,@(map prettify-flow-syntax (syntax->list #'(expr ...))))]
    [(sep
      expr ...)
     #`(sep #,@(map prettify-flow-syntax (syntax->list #'(expr ...))))]
    [(and
      expr ...)
     #`(and #,@(map prettify-flow-syntax (syntax->list #'(expr ...))))]
    [(or
      expr ...)
     #`(or #,@(map prettify-flow-syntax (syntax->list #'(expr ...))))]
    [(not
      expr ...)
     #`(not #,@(map prettify-flow-syntax (syntax->list #'(expr ...))))]
    [(all
      expr ...)
     #`(all #,@(map prettify-flow-syntax (syntax->list #'(expr ...))))]
    [(any
      expr ...)
     #`(any #,@(map prettify-flow-syntax (syntax->list #'(expr ...))))]
    [(fanout
      expr ...)
     #`(fanout #,@(map prettify-flow-syntax (syntax->list #'(expr ...))))]
    [(group
      expr ...)
     #`(group #,@(map prettify-flow-syntax (syntax->list #'(expr ...))))]
    [(if
      expr ...)
     #`(if #,@(map prettify-flow-syntax (syntax->list #'(expr ...))))]
    [(sieve
      expr ...)
     #`(sieve #,@(map prettify-flow-syntax (syntax->list #'(expr ...))))]
    [(partition
      [e1 e2] ...)
     #:with e1-prettified (map prettify-flow-syntax (attribute e1))
     #:with e2-prettified (map prettify-flow-syntax (attribute e2))
     #`(partition e1-prettified e2-prettified)]
    [(try expr
      [e1 e2] ...)
     #:with expr-prettified (prettify-flow-syntax #'expr)
     #:with e1-prettified (map prettify-flow-syntax (attribute e1))
     #:with e2-prettified (map prettify-flow-syntax (attribute e2))
     #`(try expr-prettified e1-prettified e2-prettified)]
    [(>>
      expr ...)
     #`(>> #,@(map prettify-flow-syntax (syntax->list #'(expr ...))))]
    [(<<
      expr ...)
     #`(<< #,@(map prettify-flow-syntax (syntax->list #'(expr ...))))]
    [(feedback
      expr ...)
     #`(feedback #,@(map prettify-flow-syntax (syntax->list #'(expr ...))))]
    [(loop
      expr ...)
     #`(loop #,@(map prettify-flow-syntax (syntax->list #'(expr ...))))]
    [(loop2
      expr ...)
     #`(loop2 #,@(map prettify-flow-syntax (syntax->list #'(expr ...))))]
    [(clos
      expr ...)
     #`(clos #,@(map prettify-flow-syntax (syntax->list #'(expr ...))))]
    [(esc expr) (prettify-flow-syntax #'expr)]
    [expr #'expr]))
