#lang racket/base

(require (for-syntax racket/base
                     syntax/parse
                     "../strategy.rkt")
         racket/undefined
         "../passes.rkt")

;; Transformation rules for the `as` binding form:
;;
;; 1. escape to wrap outermost ~> with let and re-enter
;;
;;   (~> flo ... (... (as name) ...))
;;   ...
;;    ↓
;;   ...
;;   (esc (let ([name (void)])
;;          (☯ original-flow)))
;;
;; 2. as → set!
;;
;;   (as name)
;;   ...
;;    ↓
;;   ...
;;   (~> (esc (λ (x) (set! name x))) ⏚)
;;
;; 3. Overall transformation:
;;
;;   (~> flo ... (... (as name) ...))
;;   ...
;;    ↓
;;   ...
;;   (esc (let ([name (void)])
;;          (☯ (~> flo ... (... (~> (esc (λ (x) (set! name x))) ⏚) ...)))))

(begin-for-syntax

  ;; (as name) → (~> (esc (λ (x) (set! name x))) ⏚)
  ;; TODO: use a box instead of set!
  (define (rewrite-all-bindings stx)
    (find-and-map/qi (syntax-parser
                       [((~datum as) x ...)
                        #:with (x-val ...) (generate-temporaries (attribute x))
                        #'(thread (esc (λ (x-val ...) (set! x x-val) ...)) ground)]
                       [_ this-syntax])
                     stx))

  (define (bound-identifiers stx)
    (let ([ids null])
      (find-and-map/qi (syntax-parser
                         [((~datum as) x ...)
                          (begin
                            (set! ids
                                  (append (attribute x) ids))
                            ;; we don't need to traverse further
                            #f)]
                         [_ this-syntax])
                       stx)
      ids))

  ;; wrap stx with (let ([v undefined] ...) stx) for v ∈ ids
  (define (wrap-with-scopes stx ids)
    (with-syntax ([(v ...) ids])
      #`(let ([v undefined] ...) #,stx)))

  (define-and-register-pass 2000 (bindings stx)
    ;; TODO: use syntax-parse and match ~> specifically.
    ;; Since macros are expanded "outside in," presumably
    ;; it will naturally wrap the outermost ~>
    (wrap-with-scopes (rewrite-all-bindings stx)
                      (bound-identifiers stx))))

