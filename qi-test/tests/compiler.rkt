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

   ;; Note that these test deforestation in isolation
   ;; without necessarily taking normalization (a preceding
   ;; step in compilation) into account
   (test-suite
    "deforestation"
    (let ([stx (syntax->list #'((#%blanket-template
                                 ((#%host-expression filter)
                                  (#%host-expression odd?)
                                  __))))])
      (check-false (deforested? (syntax->datum
                                 (deforest-rewrite
                                   #`(thread #,@stx))))
                   "does not deforest single stream component in isolation"))
    (let ([stx (syntax->list #'((#%blanket-template
                                 ((#%host-expression filter)
                                  (#%host-expression odd?)
                                  __))
                                (#%blanket-template
                                 ((#%host-expression map)
                                  (#%host-expression sqr)
                                  __))))])
      (check-true (deforested? (syntax->datum
                                (deforest-rewrite
                                  #`(thread #,@stx))))
                  "deforest filter"))
    (let ([stx (syntax->list #'((#%blanket-template
                                 ((#%host-expression range)
                                  (#%host-expression 10)
                                  __))
                                (#%blanket-template
                                 ((#%host-expression filter)
                                  (#%host-expression odd?)
                                  __))))])
      (check-true (deforested? (syntax->datum
                                (deforest-rewrite
                                  #`(thread #,@stx))))
                  "deforest range"))
    (let ([stx (syntax->list #'((#%blanket-template
                                 ((#%host-expression filter)
                                  (#%host-expression odd?)
                                  __))
                                (esc (#%host-expression car))))])
      (check-true (deforested? (syntax->datum
                                (deforest-rewrite
                                  #`(thread #,@stx))))
                  "deforest car"))
    (let ([stx (syntax->list #'((#%blanket-template
                                 ((#%host-expression filter)
                                  (#%host-expression odd?)
                                  __))
                                (#%blanket-template
                                 ((#%host-expression map)
                                  (#%host-expression sqr)
                                  __))))])
      (check-true (deforested? (syntax->datum
                                (deforest-rewrite
                                  #`(thread #,@stx))))
                  "deforest range"))
    (let ([stx #'(#%blanket-template
                  ((#%host-expression map)
                   (#%host-expression sqr)
                   __)
                  ((#%host-expression filter)
                   (#%host-expression odd?)
                   __))])
      (check-false (deforested? (syntax->datum
                                 (deforest-rewrite
                                   #`(thread #,stx))))
                   "does not deforest map in the head position"))
    ;; (~>> values (filter odd?) (map sqr) values)
    (let ([stx (syntax->list
                #'(values
                   (#%blanket-template
                    ((#%host-expression filter)
                     (#%host-expression odd?)
                     __))
                   (#%blanket-template
                    ((#%host-expression map)
                     (#%host-expression sqr)
                     __))
                   values))])
      (check-true (deforested? (syntax->datum
                                (deforest-rewrite
                                  #`(thread #,@stx))))
                  "deforestation in arbitrary positions"))
    (let ([stx (syntax->list
                #'((#%blanket-template
                    ((#%host-expression filter)
                     (#%host-expression string-upcase)
                     __))
                   (#%blanket-template
                    ((#%host-expression foldl)
                     (#%host-expression string-append)
                     (#%host-expression "I")
                     __))))])
      (check-true (deforested? (syntax->datum
                                (deforest-rewrite
                                  #`(thread #,@stx))))
                  "deforestation in arbitrary positions"))
    (let ([stx (syntax->list #'((#%fine-template
                                 ((#%host-expression filter)
                                  (#%host-expression odd?)
                                  _))
                                (#%fine-template
                                 ((#%host-expression map)
                                  (#%host-expression sqr)
                                  _))))])
      (check-true (deforested? (syntax->datum
                                (deforest-rewrite
                                  #`(thread #,@stx))))
                  "deforest fine-grained template forms")))
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
    "compilation sequences"
    null)
   (test-suite
    "fixed point"
    null)))

(module+ main
  (void (run-tests tests)))
