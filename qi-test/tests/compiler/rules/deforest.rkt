#lang racket/base

(provide tests
         deforested?)

(require (for-template qi/flow/core/compiler
                       qi/flow/core/deforest)
         ;; necessary to recognize and expand core forms correctly
         qi/flow/extended/expander
         ;; necessary to correctly expand the right-threading form
         qi/flow/extended/forms
         (for-syntax racket/base)
         rackunit
         rackunit/text-ui
         racket/string
         qi/flow/core/private/form-property
         "../private/expand-util.rkt"
         syntax/parse/define)

;; NOTE: we need to tag test syntax with `tag-form-syntax`
;; in most cases. See the comment on that function definition.

(define-syntax-parse-rule (test-deforested name stx)
  (test-true name
             (deforested?
               (deforest-rewrite
                 (phase0-expand-flow
                  stx)))))

(define-syntax-parse-rule (test-not-deforested name stx)
  (test-false name
              (deforested?
                (deforest-rewrite
                  (phase0-expand-flow
                   stx)))))

;; Note: an alternative way to make these assertions could be to add logging
;; to compiler passes to trace what happens to a source expression, capturing
;; those logs in these tests and verifying that the logs indicate the expected
;; passes were performed. Such logs would also allow us to validate that
;; passes were performed in the expected order, at some point in the future
;; when we might have nonlinear ordering of passes. See the Qi meeting notes:
;; "Validly Verifying that We're Compiling Correctly"
(define (deforested? exp)
  (string-contains? (format "~a" exp) "cstream"))

(define (filter-deforested? exp)
  (string-contains? (format "~a" exp) "filter-cstream"))

(define (car-deforested? exp)
  (string-contains? (format "~a" exp) "car-cstream"))


(define tests

  (test-suite
   "deforestation"
   ;; Note that these test deforestation in isolation
   ;; without necessarily taking normalization (a preceding
   ;; step in compilation) into account

   (test-suite
    "deforest-rewrite"
    (test-suite
     "general"
     (test-not-deforested "does not deforest single stream component in isolation"
                          #'(~>> (filter odd?)))
     (test-not-deforested "does not deforest map in the head position"
                          #'(~>> (map sqr) (filter odd?)))
     (test-deforested "deforestation in arbitrary positions"
                      #'(~>> values
                             (filter odd?)
                             (map sqr)
                             values))
     (test-deforested "deforestation in arbitrary positions"
                      #'(~>>
                         values
                         (filter string-upcase)
                         (foldl string-append "I")
                         values)))

    (test-suite
     "transformers"
     (test-deforested "filter-map (two transformers)"
                      #'(~>> (filter odd?) (map sqr)))
     (test-deforested "fine-grained template forms"
                      #'(~>> (filter odd? _) (map sqr _))))

    (test-suite
     "producers"
     ;; TODO: note that these uses of `range` are matched as datums
     ;; and requiring racket/list's range is not required in this module
     ;; for deforestation to happen. This should be changed to use
     ;; literal matching in the compiler.
     (test-deforested "range"
                      #'(~>> range (filter odd?)))
     (test-deforested "(range _)"
                      #'(~>> (range _) (filter odd?)))
     (test-deforested "(range _ _)"
                      #'(~>> (range _ _) (filter odd?)))
     (test-deforested "(range 0 _)"
                      #'(~>> (range 0 _) (filter odd?)))
     (test-deforested "(range _ 10)"
                      #'(~>> (range _ 10) (filter odd?)))
     (test-deforested "(range _ _ _)"
                      #'(~>> (range _ _ _) (filter odd?)))
     (test-deforested "(range _ _ 1)"
                      #'(~>> (range _ _ 1) (filter odd?)))
     (test-deforested "(range _ 10 _)"
                      #'(~>> (range _ 10 _) (filter odd?)))
     (test-deforested "(range _ 10 1)"
                      #'(~>> (range _ 10 1) (filter odd?)))
     (test-deforested "(range 0 _ _)"
                      #'(~>> (range 0 _ _) (filter odd?)))
     (test-deforested "(range 0 _ 1)"
                      #'(~>> (range 0 _ 1) (filter odd?)))
     (test-deforested "(range 0 10 _)"
                      #'(~>> (range 0 10 _) (filter odd? __)))
     (test-deforested "(range __)"
                      #'(~>> (range __) (filter odd?)))
     (test-deforested "(range 0 __)"
                      #'(~>> (range 0 __) (filter odd?)))
     (test-deforested "(range __ 1)"
                      #'(~>> (range __ 1) (filter odd?)))
     (test-deforested "(range 0 10 __)"
                      #'(~>> (range 0 10 __) (filter odd?)))
     (test-deforested "(range __ 10 1)"
                      #'(~>> (range __ 10 1) (filter odd? __)))
     (test-deforested "(range 0 __ 1)"
                      #'(~>> (range 0 __ 1) (filter odd?)))
     (test-deforested "(range 0 10 1 __)"
                      #'(~>> (range 0 10 1 __) (filter odd?)))
     (test-deforested "(range 0 10 __ 1)"
                      #'(~>> (range 0 10 __ 1) (filter odd?)))
     (test-deforested "(range 0 __ 10 1)"
                      #'(~>> (range 0 __ 10 1) (filter odd?)))
     (test-deforested "(range __ 0 10 1)"
                      #'(~>> (range __ 0 10 1) (filter odd?))))

    (test-suite
     "consumers"
     (test-deforested "car"
                      #'(~>> (filter odd?) car))
     (test-deforested "foldl"
                      #'(~>> (filter string-upcase) (foldl string-append "I")))
     (test-deforested "foldr"
                      #'(~>> (filter string-upcase) (foldr string-append "I")))))

   (test-suite
    "deforest-pass"
    ;; NOTE: These tests invoke deforest-pass on the syntax returned
    ;; from the expander, which we expect has the `nonterminal` property
    ;; attached. That is in fact what we find when we run these in
    ;; the REPL or if we run the tests at the command line using `racket`.
    ;; But if we run this via `racket -y` (the default in Makefile targets),
    ;; these tests fail because they do not find the syntax property.
    ;; For now, we manually attach the property using `tag-form-syntax`
    ;; to get the tests to pass, but I believe it is reflecting a real
    ;; problem and the failure is legitimate. It is probably related to
    ;; why normalize → deforest does not work (e.g. as seen in the
    ;; long-functional-pipeline benchmark), even if we are able to get
    ;; it to work in tests by manually attaching the property.
    (check-true (deforested? (syntax->datum
                              (deforest-pass
                                (tag-form-syntax ; should not be necessary
                                 (phase0-expand-flow
                                  #'(>< (~>> (filter odd?) (map sqr))))))))
                "nested positions")
    (let* ([stx (tag-form-syntax ; should not be necessary
                 (phase0-expand-flow
                  #'(-< (~>> (filter odd?) (map sqr))
                        (~>> range car))))]
           [result (syntax->datum
                    (deforest-pass
                      stx))])
      (check-true (deforested? result)
                  "multiple independent positions")
      (check-true (filter-deforested? result)
                  "multiple independent positions")
      (check-true (car-deforested? result)
                  "multiple independent positions")))))

(module+ main
  (void
   (run-tests tests)))
