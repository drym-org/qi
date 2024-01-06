#lang racket/base

(provide define-qi-expansion-step)

(require macro-debugger/emit)

;; These macros emit expansion "events" that allow the macro
;; stepper to report stages in the expansion of an expression,
;; giving us visibility into this process for debugging purposes.
;; Note that this currently does not distinguish substeps
;; of a parent expansion step.
(define (qi-expansion-step name stx0 stx1)
  (emit-local-step stx0 stx1 #:id name)
  stx1)

(define-syntax-rule (define-qi-expansion-step (name stx0)
                      body ...)
  (define (name stx0)
    (let ([stx1 (let () body ...)])
      (qi-expansion-step #'name stx0 stx1))))
