#lang racket/base

(provide tests)

(require (for-syntax racket/base)
         rackunit
         rackunit/text-ui
         racket/function
         racket/list
         racket/math
         ;; necessary to recognize and expand core forms correctly
         qi/flow/extended/expander
         ;; necessary to correctly expand the right-threading form
         qi/flow/extended/forms
         (submod qi/flow/extended/expander invoke)
         qi/flow/core/compiler
         (for-template qi/flow/core/compiler)
         qi/on
         qi/macro
         qi/flow)

;; NOTE: we may need to tag test syntax with `tag-form-syntax`
;; in some cases. See the comment on that function definition.
;; It's not necessary if we are directly using the expander
;; output, as that already includes the property, but we might
;; need to reattach it if we tranform that syntax in some way.

(define (runs-within-time? f timeout)
  (define handle (thread f))
  (define result (sync/timeout timeout handle))
  (kill-thread handle) ; no-op if already dead
  (not (not result)))

(define (all-disappeared-uses stx)
  (define uses '())
  (let loop ([stx stx])
    (define stx-e
      (cond
        [(syntax? stx)
         (define stx-uses (syntax-property stx 'disappeared-use))
         (when stx-uses (set! uses (cons stx-uses uses)))
         (syntax-e stx)]
        [else stx]))
    (cond
      [(list? stx-e)
       (for-each loop stx-e)]
      [(pair? stx-e)
       (loop (car stx-e))
       (loop (cdr stx-e))]
      [(vector? stx-e)
       (for ([substx (in-vector stx-e)])
         (loop substx))]
      [else (void)]))
  (flatten uses))

(define (datum-identifier=? left right)
  (eq? (syntax-e left) (syntax-e right)))

(define (datum-member? elt elts)
  (member elt elts datum-identifier=?))

(define tests

  (test-suite
   "inlining"

   (test-true "does not enter infinite loop"
              (runs-within-time?
               (thunk
                (expand
                 #'(let ()
                     (define-flow f (if odd? (~> add1 f) _))
                     (f 4))))
               1.0))
   (test-equal? "does inline occurrences in sequence"
                (caddr
                 (syntax->datum
                  (expand
                   #'(let ()
                       (define-flow f (if odd? (~> add1 f f) _))
                       (f 4)))))
                (caddr
                 (syntax->datum
                  (expand
                   #'(let ()
                       (define flow:f
                         (flow
                          (if odd?
                              (~> add1
                                  (if odd? (~> add1 flow:f flow:f) _)
                                  (if odd? (~> add1 flow:f flow:f) _))
                              _)))
                       (flow:f 4))))))
   ;; this ensures that expansion of flow definitions is deferred at
   ;; least until the rest of the definition context is partially
   ;; expanded
   (test-equal? "supports macros defined after the flow"
                (let ()
                  (define-flow f (~> (pare sqr +) ▽))
                  (define-qi-syntax-rule (pare car-flo cdr-flo)
                    (group 1 car-flo cdr-flo))
                  (on (3 6 9) f))
                '(9 15))
   ;; this ensures that even if the flow is inlined, DrRacket still tracks
   ;; the usage
   (test-check "adds 'disappeared-use property"
               datum-member?
               #'my-flow
               (all-disappeared-uses
                (expand #'(let ()
                            (define-flow my-flow +)
                            (flow my-flow)))))
   (test-equal? "inlining does not mess up bindings 1"
                (let ()
                  (define-flow f (~> (as x) (gen 0)))
                  (on (1) (~> (as x) (gen 2) f (gen x))))
                1)
   (test-equal? "inlining does not mess up bindings 2"
                (let ()
                  (define x 2)
                  (define-flow f (gen x))
                  (on (1) (~> (as x) f)))
                2)))

(module+ main
  (void
   (run-tests tests)))
