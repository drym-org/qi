#lang racket/base

(provide find-and-map/qi
         fix)

(require racket/match
         syntax/parse)

;; Walk the syntax tree in a "top down" manner, i.e. from the root down
;; to the leaves, applying a transformation to each node. The
;; transforming function is expected to either return the transformed
;; syntax or false. The traversal terminates in the former case (i.e. it
;; does not traverse the transformed expression to look for further
;; matches), and continues in the latter case.
(define (find-and-map f stx)
  ;; f : syntax? -> (or/c syntax? #f)
  (match stx
    [(? syntax?) (let ([stx^ (f stx)])
                   (or stx^ (datum->syntax stx
                              (find-and-map f (syntax-e stx))
                              stx
                              stx)))]
    [(cons a d) (cons (find-and-map f a)
                      (find-and-map f d))]
    [_ stx]))

;; A thin wrapper around find-and-map that does not traverse subexpressions
;; that are tagged as host language (rather than Qi) expressions
(define (find-and-map/qi f stx)
  ;; #%host-expression is a Racket macro defined by syntax-spec
  ;; that resumes expansion of its sub-expression with an
  ;; expander environment containing the original surface bindings
  (find-and-map (syntax-parser [((~datum #%host-expression) e:expr) this-syntax]
                               [_ (f this-syntax)])
                stx))

;; Applies f repeatedly to the init-val terminating the loop if the
;; result of f is #f or the new syntax object is eq? to the previous
;; (possibly initial) one.
;;
;; Caveats:
;;   * the syntax object is not inspected, only eq? is used
;;   * comparison is performed only between consecutive steps (does not handle cyclic occurences)
(define ((fix f) init-val)
  (let ([new-val (f init-val)])
    (if (or (not new-val)
            (eq? new-val init-val))
        init-val
        ((fix f) new-val))))
