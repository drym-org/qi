#lang racket/base

;; In traversing Qi syntax to apply optimization rules in the compiler,
;; we only want to apply such rules to syntax that is a legitimate use of
;; a core Qi form. A naive tree traversal may in some cases yield
;; subexpressions that aren't valid Qi syntax on their own, and we need a
;; way to a avoid attempting to optimize these. The "right way" remains
;; to be defined (e.g. either we do a tree traversal that is not naive
;; and is aware of the core language grammar, or Syntax Spec provides
;; such a traversal utility inferred from the core language grammar (for
;; use by any language), or something else. But for now, Syntax Spec
;; helps us out by attaching a syntax property to each such legitimate
;; use of core language syntax, and we look for that during tree
;; traversal (i.e. in `find-and-map`), only optimizing if it is present.
;; Whenever we synthesize syntax as part of compiler transformations, we
;; need to propagate this property too, so that subsequent optimization
;; passes see it. We also need to attach this property in tests.

(provide form-position?
         attach-form-property
         tag-form-syntax)

(require (only-in racket/function
                  curry))

(define (form-position? v)
  (and (syntax? v)
       (syntax-property v 'nonterminal)))

(define (syntax-list? v)
  (and (syntax? v) (syntax->list v)))

(define (tree-map f tree)
  (cond [(list? tree) (map (curry tree-map f)
                           tree)]
        [(syntax-list? tree) (f (datum->syntax tree
                                  (tree-map f (syntax->list tree))
                                  tree
                                  tree))]
        [else (f tree)]))

(define (attach-form-property stx)
  (syntax-property stx 'nonterminal 'floe))

;; This traverses a syntax object and indiscriminately tags every node
;; as a form. If this operation were applied to syntax in the real
;; compiler, it would of course lead to the incorrect optimizations we
;; originally added the property to correct.
;; **It is only appropriate for use in tests.**
(define (tag-form-syntax stx)
  (tree-map attach-form-property stx))
