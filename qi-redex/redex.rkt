#lang racket/base

(require redex/reduction-semantics)

(provide Qi floe-reduce)

(define-language Qi
  ;; Variables
  (x ::= variable-not-otherwise-mentioned)
  (n ::= number)
  ;; Lambda calculus / Racket expressions
  (e ::= (λ (x ...) e) (e e ...) x n (values e ...))
  ;; Lambda calculus contexts
  (E ::= hole (v ... E e ...) (values v ... E e ...))
  ;; Normalised terms / Racket values
  (v ::= (λ (x ...) e) n)
  ;; Flow expressions
  (f ::=
     (~> f ...)
     (-< f ...)
     (== f ...)
     (gen e ...)
     (esc e)
     (>< f))
  ;; Flow values (normalised flows)
  (fv ::= (gen v ...))
  ;; Flow contexts
  (F ::= hole
     (~> fv ... F f ...)
     (-< fv ... F f ...)
     (== fv ... F f ...)
     (gen v ... E e ...)
     (esc E)
     (>< F))

  #:binding-forms
  (λ (x ...) e #:refers-to (shadow x ...)))

(define-metafunction Qi
  β-reduce : (λ (x ..._1) e) e ..._1 -> e
  [(β-reduce (λ (x ...) e) e_x ...) (substitute e [x e_x] ...)])

;; Floe reductions
(define floe-reduce
  (reduction-relation
   Qi
   ;; Threading
   (--> (in-hole F (~> (gen v ...) (esc v_1) f ...))
        (in-hole F (~> (gen (v_1 v ...)) f ...))
        thread-step)
   (--> (in-hole F (~> (gen v ...)))
        (in-hole F (gen v ...))
        thread-red)
   ;; Tee
   (--> (in-hole F (~> (gen v ...) (-< f ...)))
        (in-hole F (-< (~> (gen v ...) f) ...))
        tee-step)
   (--> (in-hole F (-< (gen v ...) ...))
        (in-hole F (gen v ... ...))
        tee-red)
   ;; Relay
   (--> (in-hole F (~> (gen v ...) (== f ...)))
        (in-hole F (-< (~> (gen v) f) ...))
        relay-red)
   ;; Amp
   (--> (in-hole F (~> (gen v ...) (>< f)))
        (in-hole F (-< (~> (gen v) f) ...))
        amp-red)
   ;; Gen
   (--> (in-hole F (gen v_1 ... (values v_2 ...) e ...))
        (in-hole F (gen v_1 ... v_2 ... e ...))
        gen-values)
   (--> (in-hole F (~> (gen v_1 ...) (gen v_2 ...)))
        (in-hole F (gen v_2 ...))
        gen-red)

   ;; Lambda calculus reductions
   (--> (in-hole F ((λ (x ...) e) v ...))
        (in-hole F (mf-apply β-reduce (λ (x ...) e) v ...))
        beta-red)))

(module+ test
  (test-->
   floe-reduce
   (term (~> (gen 0)))
   (term (gen 0)))

  (test-->
   floe-reduce
   (term (~> (~> (gen 0))))
   (term (~> (gen 0))))

  (test-match Qi f (term (esc (λ (x) x))))
  (test-match Qi fv (term (gen 1)))

  (test-->
   floe-reduce
   (term (~> (gen 1) (esc (λ (x) x))))
   (term (~> (gen ((λ (x) x) 1)))))

  (test-->
   floe-reduce
   (term (gen ((λ (x) x) 1)))
   (term (gen 1)))

  (test-->>
   floe-reduce
   (term (~> (gen 1) (esc (λ (x) x))))
   (term (gen 1)))

  (test-->
   floe-reduce
   (term (gen (values 1 2 3)))
   (term (gen 1 2 3)))

  (test-->>
   floe-reduce
   (term (~> (gen 1 2)
             (-< (esc (λ (x y) y))
                 (esc (λ (x y) x)))))
   (term (gen 2 1)))

  (test-->>
   floe-reduce
   (term (~> (gen 1 2)
             (-< (esc (λ (x y) (values x y)))
                 (esc (λ (x y) (values y x))))))
   (term (gen 1 2 2 1)))

  (test-->>
   floe-reduce
   (term (~> (gen 1 2)
             (== (esc (λ (x) (values 0 x)))
                 (esc (λ (x) (values x 3))))))
   (term (gen 0 1 2 3)))

  (test-->>
   floe-reduce
   (term (~> (gen 1 2)
             (>< (esc (λ (x) (values x 0))))))
   (term (gen 1 0 2 0)))

  (test-->
   floe-reduce
   (term (~> (gen 1 2 3) (gen 4)))
   (term (gen 4))))
