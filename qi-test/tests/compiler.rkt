#lang racket/base

(provide tests)

(require (for-template qi/flow/core/deforest
                       qi/flow/core/compiler)
         (only-in qi/flow/extended/syntax
                  make-right-chiral)
         rackunit
         rackunit/text-ui
         (only-in math sqr))

(define-syntax-rule (test-normalize a b msg)
  (check-equal? (syntax->datum
                 (normalize-pass a))
                (syntax->datum
                 (normalize-pass b))
                msg))

(define tests
  (test-suite
   "compiler tests"

   (test-suite
    "deforestation"
    (let ([stx (map make-right-chiral
                    (syntax->list #'((#%partial-application
                                      ((#%host-expression filter)
                                       (#%host-expression odd?)))
                                     (#%partial-application
                                      ((#%host-expression map)
                                       (#%host-expression sqr))))))])
      (check-equal? (syntax->datum
                     (deforest-rewrite
                       #`(thread #,@stx)))
                    '(thread
                      (esc
                       (λ args
                         ((cstream-next->list (inline-compose1 (map-cstream-next sqr) (filter-cstream-next odd?) list->cstream-next))
                          (apply identity args)))))
                    "deforest filter"))
    (let ([stx (make-right-chiral
                #'(#%partial-application
                   ((#%host-expression map)
                    (#%host-expression sqr))))])
      ;; note this tests the rule in isolation; with normalization this would never be necessary
      (check-equal? (syntax->datum
                     (deforest-rewrite
                       #`(thread #,stx)))
                    '(thread (#%partial-application ((#%host-expression map) (#%host-expression sqr))))
                    "does not deforest map in the head position"))
    ;; (~>> values (filter odd?) (map sqr) values)
    (let ([stx (map make-right-chiral
                    (syntax->list
                     #'(values
                        (#%partial-application
                         ((#%host-expression filter)
                          (#%host-expression odd?)))
                        (#%partial-application
                         ((#%host-expression map)
                          (#%host-expression sqr)))
                        values)))])
      (check-equal? (syntax->datum
                     (deforest-rewrite
                       #`(thread #,@stx)))
                    '(thread
                      values
                      (esc
                       (λ args
                         ((cstream-next->list
                           (inline-compose1
                            (map-cstream-next
                             sqr)
                            (filter-cstream-next
                             odd?)
                            list->cstream-next))
                          (apply identity args))))
                      values)
                    "deforestation in arbitrary positions"))
    (let ([stx (map make-right-chiral
                    (syntax->list
                     #'((#%partial-application
                         ((#%host-expression filter)
                          (#%host-expression string-upcase)))
                        (#%partial-application
                         ((#%host-expression foldl)
                          (#%host-expression string-append)
                          (#%host-expression "I"))))))])
      (check-equal? (syntax->datum
                     (deforest-rewrite
                       #`(thread #,@stx)))
                    '(thread
                      (esc
                       (λ args
                         ((foldl-cstream-next
                           string-append
                           "I"
                           (inline-compose1
                            (filter-cstream-next
                             string-upcase)
                            list->cstream-next))
                          (apply identity args)))))
                    "deforestation in arbitrary positions")))
   (test-suite
    "normalization"
    (test-normalize #'(thread
                       (thread (filter odd?)
                               (map sqr)))
                    #'(thread (filter odd?)
                              (map sqr))
                    "nested threads are collapsed")
    (test-normalize #'(thread values
                              sqr)
                    #'(thread sqr)
                    "values inside threading is elided")
    (test-normalize #'(thread sqr)
                    #'sqr
                    "trivial threading is collapsed"))
   (test-suite
    "fixed point"
    null)))

(module+ main
  (void (run-tests tests)))
