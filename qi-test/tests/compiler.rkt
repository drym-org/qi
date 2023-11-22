#lang racket/base

(provide tests)

(require (for-template qi/flow/core/deforest
                       qi/flow/core/compiler)
         (only-in qi/flow/extended/syntax
                  make-right-chiral)
         rackunit
         rackunit/text-ui
         (only-in math sqr)
         racket/string)

(define-syntax-rule (test-normalize a b msg)
  (check-equal? (syntax->datum
                 (normalize-pass a))
                (syntax->datum
                 (normalize-pass b))
                msg))

(define (deforested? exp)
  (string-contains? (format "~a" exp) "cstream"))


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
      (check-true (deforested? (syntax->datum
                                (deforest-rewrite
                                  #`(thread #,@stx))))
                  "deforest filter"))
    (let ([stx (make-right-chiral
                #'(#%partial-application
                   ((#%host-expression map)
                    (#%host-expression sqr))))])
      ;; note this tests the rule in isolation; with normalization this would never be necessary
      (check-false (deforested? (syntax->datum
                                 (deforest-rewrite
                                   #`(thread #,stx))))
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
      (check-true (deforested? (syntax->datum
                                (deforest-rewrite
                                  #`(thread #,@stx))))
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
      (check-true (deforested? (syntax->datum
                                (deforest-rewrite
                                  #`(thread #,@stx))))
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
