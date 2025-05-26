#lang racket/base

(provide on
         flow-lambda
         flow-λ
         π
         define-flow)

(require syntax/parse/define
         (for-syntax racket/base
                     syntax/parse/lib/function-header
                     "flow/aux-syntax.rkt"
                     racket/syntax)
         (only-in "flow/core/compiler/0005-inline.rkt"
                  flowdef)
         "flow.rkt"
         (only-in "private/util.rkt"
                  define-alias
                  params-parser))

(define-syntax-parser on
  [(_ args:subject)
   #:with ags (attribute args.args)
   #`((flow) #,@(syntax->list #'ags))]
  [(_ args:subject clause:clause)
   #:with ags (attribute args.args)
   #`((flow clause) #,@(syntax->list #'ags))])

;; The parsed `ags' is being passed to `on'
;; while the unparsed `args' are passed to `lambda',
;; so that `lambda' can bind keyword arguments in scope
;; while the flow itself does not receive them directly.
(define-syntax-parser flow-lambda
  [(_ args:formals clause:clause)
   #:with ags (params-parser #'args)
   #'(lambda args
       (on ags
           clause))])

(define-alias π flow-lambda)
(define-alias flow-λ flow-lambda)

;; TODO: disallow set! of these bindings to anything else
(define-syntax-parser define-flow
  [(_ ((~or* head:id head:function-header) . args:formals)
      clause:clause)
   #'(define head
       (flow-lambda args
                    clause))]
  [(_ name:id clause:clause)
   #:with new-name (format-id #'hi "flow:~a" #'name)
   #'(begin
       (define-syntax name
         (flowdef #'new-name #'clause))
       (define new-name
         (flow clause)))])
