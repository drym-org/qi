#lang racket/base

(require (for-syntax racket/base
                     (for-syntax racket/base)
                     macro-debugger/emit))

(provide (for-syntax define-pass
                     run-passes))

(begin-for-syntax

  ;; Could be a list but for future extensibility a custom struct is
  ;; probably a better idea.
  (struct passdef (name prio parser) #:transparent)

  ;; Syntax-phase box for user-module-specific ordered list of
  ;; compiler passes.
  (define registered-passes (box '()))

  ;; Low-level pass registration: symbol (name), number (priority) and
  ;; procedure accepting the syntax (parser).
  (define (register-pass name prio parser)
    (set-box! registered-passes
              (sort (cons (passdef name prio parser)
                          (unbox registered-passes))
                    (lambda (a b)
                      (< (passdef-prio a)
                         (passdef-prio b))))))

  ;; Syntax macro wrapper for convenient definitions of compiler
  ;; passes. Should be used by modules implementing passes.
  (define-syntax (define-pass stx)
    (syntax-case stx ()
      ((_ prio (name stx) expr ...)
       #'(register-pass #'name prio (lambda (stx) expr ...)))))

  ;; Runs registered passes on given syntax object - should be used by
  ;; the actual compiler.
  (define (run-passes stx)
    (displayln registered-passes)
    (for/fold ((stx stx))
              ((pass (in-list (unbox registered-passes))))
      (define stx1 ((passdef-parser pass) stx))
      (emit-local-step stx stx1 #:id (passdef-name pass))
      stx1))

  )
