#lang racket/base

(provide make-eval-for-docs)

(require racket/sandbox)

(define (make-eval-for-docs . exprs)
  ;; The "trusted" sandbox configuration is needed possibly
  ;; because of the interaction of binding spaces with
  ;; sandbox evaluator. For more context, see the Qi wiki
  ;; "Qi Compiler Sync Sept 2 2022."
  (call-with-trusted-sandbox-configuration
   (lambda ()
     (parameterize ([sandbox-output 'string]
                    [sandbox-error-output 'string]
                    [sandbox-memory-limit #f])
       (apply make-evaluator
              'racket/base
              '(require qi
                        qi/probe
                        (only-in racket/list range first rest)
                        racket/format
                        racket/string
                        (only-in racket/function curry)
                        (for-syntax syntax/parse
                                    racket/base))
              '(define (sqr x)
                 (* x x))
              '(define ->string number->string)
              exprs)))))
