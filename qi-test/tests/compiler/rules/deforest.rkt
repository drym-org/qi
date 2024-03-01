#lang racket/base

(provide tests)

(require (for-syntax racket/base)
         "private/deforest-util.rkt"
         ;; necessary to recognize and expand core forms correctly
         qi/flow/extended/expander
         ;; necessary to correctly expand the right-threading form
         qi/flow/extended/forms
         qi/flow/core/compiler
         qi/flow/core/deforest
         syntax/macro-testing
         (submod qi/flow/extended/expander invoke)
         rackunit
         rackunit/text-ui
         syntax/parse/define)

;; NOTE: we need to tag test syntax with `tag-form-syntax`
;; in some cases. See the comment on that function definition.

(define-syntax-parse-rule (test-deforested name stx)
  (test-true name
             (deforested?
               (phase1-eval
                (deforest-pass
                  (expand-flow stx))))))

(define-syntax-parse-rule (test-not-deforested name stx)
  (test-false name
              (deforested?
                (phase1-eval
                 (deforest-pass
                   (expand-flow stx))))))


(define tests

  (test-suite
   "deforestation"
   ;; Note that these test deforestation in isolation
   ;; without necessarily taking normalization (a preceding
   ;; step in compilation) into account

   (test-suite
    "deforest-pass"
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
    (test-true "nested positions"
               (deforested? (phase1-eval
                             (deforest-pass
                               (expand-flow
                                #'(>< (~>> (filter odd?) (map sqr))))))))
    (let ([stx (phase1-eval
                (deforest-pass
                  (expand-flow
                   #'(-< (~>> (filter odd?) (map sqr))
                         (~>> range car)))))])
      (test-true "multiple independent positions"
                 (deforested? stx))
      (test-true "multiple independent positions"
                 (filter-deforested? stx))
      (test-true "multiple independent positions"
                 (car-deforested? stx))))))

(module+ main
  (void
   (run-tests tests)))
