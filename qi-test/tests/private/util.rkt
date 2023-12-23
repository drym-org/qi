#lang racket

(provide sum
         flip
         sort
         true.
         my-and
         my-or
         also-or
         also-and
         tag-syntax
         (for-space qi
                    also-and
                    double-me
                    add-two))

(require (prefix-in b: racket/base)
         qi)

(define (sum lst)
  (apply + lst))

(define (flip f)
  (λ (x y . args)
    (apply f y x args)))

(define (sort less-than? #:key key . vs)
  (b:sort (map key vs) less-than?))

(define true.
  (procedure-rename (const #t)
                    'true.))

(define-syntax my-and
  (make-rename-transformer #'and))

(define-syntax my-or
  (make-rename-transformer #'or))

(define-syntax also-or
  (make-rename-transformer #'or))

(define-syntax also-and
  (make-rename-transformer #'and))

;; used to test defining and providing a qi macro "for space"
(define-qi-syntax-parser also-and
  [(_ flo ...) #''hello])

;; to test providing registered foreign syntaxes "for space"
(define-syntax-rule (double-me x) (* 2 x))

(define-syntax-rule (add-two x y) (+ x y))

(define-qi-foreign-syntaxes double-me)

(define-qi-foreign-syntaxes add-two)

(define (syntax-list? v)
  (and (syntax? v) (syntax->list v)))

(define (tree-map f tree)
  (cond [(list? tree) (map (curry tree-map f)
                           tree)]
        [(syntax-list? tree) (f (datum->syntax tree
                                  (tree-map f (syntax->list tree))))]
        [else (f tree)]))

(define (attach-form-property stx)
  (syntax-property stx 'nonterminal 'floe))

;; In traversing Qi syntax to apply optimization rules in the compiler,
;; we only want to apply such rules to syntax that is a legitimate use of
;; a core Qi form. A naive tree traversal may in some cases yield
;; subexpressions that aren't valid Qi syntax on their own, and we
;; need a way to a avoid attempting to optimize these. The "right way"
;; remains to be defined (e.g. either we do a tree traversal that is
;; not naive and is aware of the core language grammar, or Syntax Spec
;; provides such a traversal utility inferred from the core language grammar
;; (for use by any language), or something else. But for now, Syntax Spec
;; helps us out by attaching a syntax property to each such legitimate use
;; of core language syntax, and we look for that during tree traversal
;; (i.e. in `find-and-map`), only optimizing if it is present. In order
;; to test rewrite rules, we need to attach such a property too, in syntax
;; that we use in testing, and that's what this utility does.
(define (tag-syntax stx)
  (tree-map attach-form-property stx))
