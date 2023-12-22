#lang racket/base

(provide find-and-map/qi
         fix)

(require racket/match
         syntax/parse)

;; Walk the syntax tree in a "top down" manner, i.e. from the root down
;; to the leaves, applying a transformation to each node.
;; The transforming function is expected to either return transformed
;; syntax or false.
;; The traversal terminates at a node if either the transforming function
;; "succeeds," returning syntax different from the original, or if it
;; returns false, indicating that the node should not be explored.
;; In the latter case, the node is left unchanged.
;; Otherwise, as long as the transformation is the identity, it will continue
;; traversing subexpressions of the node.
(define (find-and-map f stx)
  ;; f : syntax? -> (or/c syntax? #f)
  (match stx
    [(? syntax?) (let ([stx^ (f stx)])
                   (if stx^
                       (if (eq? stx^ stx)
                           ;; no transformation was applied, so
                           ;; keep traversing
                           (datum->syntax stx
                             (find-and-map f (or (syntax->list stx)
                                                 (syntax-e stx)))
                             stx
                             stx)
                           ;; transformation was applied, so we stop
                           stx^)
                       ;; false was returned, so we stop
                       stx))]
    [(cons a d) (cons (find-and-map f a)
                      (find-and-map f d))]
    [_ stx]))

;; A thin wrapper around find-and-map that does not traverse subexpressions
;; that are tagged as host language (rather than Qi) expressions
(define (find-and-map/qi f stx)
  ;; #%host-expression is a Racket macro defined by syntax-spec
  ;; that resumes expansion of its sub-expression with an
  ;; expander environment containing the original surface bindings
  (find-and-map (syntax-parser [((~datum #%host-expression) e:expr) #f]
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
