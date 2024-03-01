#lang racket/base

(require (for-syntax racket/base
                     (for-syntax racket/base racket/syntax)
                     macro-debugger/emit))

(provide (for-syntax define-and-register-pass
                     run-passes))

(begin-for-syntax

  ;; Could be a list but for future extensibility a custom struct is
  ;; probably a better idea.
  (struct passdef (name prio parser) #:transparent)

  ;; Syntax-phase box for user-module-specific ordered list of
  ;; compiler passes.
  (define registered-passes (box '()))

  ;; Low-level pass registration: symbol (name), number (priority) and
  ;; procedure accepting the syntax (parser). Sorting upon
  ;; registration is prefered as register-pass is evaluated only once
  ;; per registered pass but run-passes can be evaluated many more
  ;; times - once for each compiled flow.
  (define (register-pass name prio parser)
    (set-box! registered-passes
              (sort (cons (passdef name prio parser)
                          (unbox registered-passes))
                    <
                    #:key passdef-prio)))

  ;; Syntax macro wrapper for convenient definitions of compiler
  ;; passes. Should be used by modules implementing passes.
  (define-syntax (define-and-register-pass stx)
    (syntax-case stx ()
      ((_ prio (name stx) expr ...)
       #'(begin
           (define name (lambda (stx) expr ...))
           (register-pass #'name prio name)
           ))))

  ;; Runs registered passes on given syntax object - should be used by
  ;; the actual compiler.
  (define (run-passes stx)
    (for/fold ((stx stx))
              ((pass (in-list (unbox registered-passes))))
      (define stx1 ((passdef-parser pass) stx))
      (emit-local-step stx stx1 #:id (passdef-name pass))
      stx1))

  )
