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

;; TODO: improve to match actual syntax-parse syntax
;; also, this doesn't seem to accept identifier macros
;; in the pattern atm,
;; e.g. (define-qi-syntax-parser kazam [_:id #''hello])
;; kazam: illegal use of syntax
;;   in: kazam
;;   value at phase 1: #<qi-macro>
;; -> probably caused by using explicit (m expr ...) in the flow
;;    expansion rule.
(define-syntax-parse-rule (define-qi-syntax-parser name (pat template) ...)
  (define-syntax name
    (qi-macro
     (syntax-parser
       (pat template) ...))))
