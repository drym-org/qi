#lang racket/base

(provide fsp-range
         fsp-default

         fst-filter
         fst-map
         fst-filter-map
         fst-take

         fsc-foldr
         fsc-foldl
         fsc-list-ref
         fsc-length
         fsc-empty?
         fsc-default

         define-and-register-deforest-pass
         )

(require syntax/parse
         "../../passes.rkt"
         "../../strategy.rkt"
         (for-template racket/base
                       "../../passes.rkt"
                       "../../strategy.rkt"
                       "templates.rkt"
                       (prefix-in qi: "bindings.rkt"))
         (for-syntax racket/base
                     syntax/parse))

(define-literal-set fs-literals
  #:datum-literals (esc #%host-expression #%fine-template #%blanket-template _ __)
  ())

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;; Producers

(define-syntax-class fsp-range
  #:attributes (blanket? fine? arg pre-arg post-arg)
  #:literal-sets (fs-literals)
  #:literals (qi:range)
  (pattern (esc (#%host-expression qi:range))
           #:attr arg #f
           #:attr pre-arg #f
           #:attr post-arg #f
           #:attr blanket? #f
           #:attr fine? #f)
  (pattern (#%fine-template
            ((#%host-expression qi:range)
             the-arg ...))
           #:attr arg #'(the-arg ...)
           #:attr pre-arg #f
           #:attr post-arg #f
           #:attr blanket? #f
           #:attr fine? #t)
  (pattern (#%blanket-template
            ((#%host-expression qi:range)
             (#%host-expression the-pre-arg) ...
             __
             (#%host-expression the-post-arg) ...))
           #:attr arg #f
           #:attr pre-arg #'(the-pre-arg ...)
           #:attr post-arg #'(the-post-arg ...)
           #:attr blanket? #t
           #:attr fine? #f))

(define-syntax-class fsp-default
  #:datum-literals (list->cstream)
  (pattern list->cstream
           #:attr contract #'(-> list? any)
           #:attr name #''list->cstream))

(define-syntax-class fsp-syntax
  (pattern (~or _:fsp-range
                _:fsp-default)))

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;; Transformers

(define-syntax-class fst-filter
  #:attributes (f)
  #:literal-sets (fs-literals)
  #:literals (qi:filter)
  (pattern (#%blanket-template
            ((#%host-expression qi:filter)
             (#%host-expression f)
             __)))
  (pattern (#%fine-template
            ((#%host-expression qi:filter)
             (#%host-expression f)
             _))))

(define-syntax-class fst-map
  #:attributes (f)
  #:literal-sets (fs-literals)
  #:literals (qi:map)
  (pattern (#%blanket-template
            ((#%host-expression qi:map)
             (#%host-expression f)
             __)))
  (pattern (#%fine-template
            ((#%host-expression qi:map)
             (#%host-expression f)
             _))))

(define-syntax-class fst-filter-map
  #:attributes (f)
  #:literal-sets (fs-literals)
  #:literals (qi:filter-map)
  (pattern (#%blanket-template
            ((#%host-expression qi:filter-map)
             (#%host-expression f)
             __)))
  (pattern (#%fine-template
            ((#%host-expression qi:filter-map)
             (#%host-expression f)
             _))))

(define-syntax-class fst-take
  #:attributes (n)
  #:literal-sets (fs-literals)
  #:literals (qi:take)
  (pattern (#%blanket-template
            ((#%host-expression qi:take)
             __
             (#%host-expression n))))
  (pattern (#%fine-template
            ((#%host-expression qi:take)
             _
             (#%host-expression n)))))

(define-syntax-class fst-intf0
  (pattern (~or filter:fst-filter
                filter-map:fst-filter-map)))

(define-syntax-class fst-syntax
  (pattern (~or _:fst-filter
                _:fst-map
                _:fst-filter-map
                _:fst-take)))

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;; Consumers

(define-syntax-class fsc-foldr
  #:attributes (op init)
  #:literal-sets (fs-literals)
  #:literals (qi:foldr)
  (pattern (#%blanket-template
            ((#%host-expression qi:foldr)
             (#%host-expression op)
             (#%host-expression init)
             __)))
  (pattern (#%fine-template
            ((#%host-expression qi:foldr)
             (#%host-expression op)
             (#%host-expression init)
             _))))

(define-syntax-class fsc-foldl
  #:attributes (op init)
  #:literal-sets (fs-literals)
  #:literals (qi:foldl)
  (pattern (#%blanket-template
            ((#%host-expression qi:foldl)
             (#%host-expression op)
             (#%host-expression init)
             __)))
  (pattern (#%fine-template
            ((#%host-expression qi:foldl)
             (#%host-expression op)
             (#%host-expression init)
             _))))

(define-syntax-class cad*r-datum
  #:attributes (countdown)
  (pattern (~literal qi:car) #:attr countdown #'0)
  (pattern (~literal qi:cadr) #:attr countdown #'1)
  (pattern (~literal qi:caddr) #:attr countdown #'2)
  (pattern (~literal qi:cadddr) #:attr countdown #'3))

(define-syntax-class fsc-list-ref
  #:attributes (pos name)
  #:literal-sets (fs-literals)
  #:literals (qi:list-ref)
  (pattern (~or (#%fine-template
                 ((#%host-expression qi:list-ref) _ idx))
                (#%blanket-template
                 ((#%host-expression qi:list-ref) __ idx)))
           #:attr pos #'idx
           #:attr name #'list-ref)
  (pattern (~or (esc (#%host-expression cad*r:cad*r-datum))
                (#%fine-template
                 ((#%host-expression cad*r:cad*r-datum) _))
                (#%blanket-template
                 ((#%host-expression cad*r:cad*r-datum) __)))
           #:attr pos #'cad*r.countdown
           #:attr name #'cad*r))

(define-syntax-class fsc-length
  #:literal-sets (fs-literals)
  #:literals (qi:length)
  (pattern (esc
            (#%host-expression qi:length)))
  (pattern (#%fine-template
            ((#%host-expression qi:length) _)))
  (pattern (#%blanket-template
            ((#%host-expression qi:length) __))))

(define-syntax-class fsc-empty?
  #:literal-sets (fs-literals)
  #:literals (qi:null? qi:empty?)
  (pattern (esc
            (#%host-expression (~or qi:empty?
                                    qi:null?))))
  (pattern (#%fine-template
            ((#%host-expression (~or qi:empty?
                                     qi:null?)) _)))
  (pattern (#%blanket-template
            ((#%host-expression (~or qi:empty?
                                     qi:null?)) __))))

(define-syntax-class fsc-default
  #:datum-literals (cstream->list)
  (pattern cstream->list))

(define-syntax-class fsc-syntax
  (pattern (~or _:fsc-foldr
                _:fsc-foldl
                _:fsc-list-ref
                _:fsc-length
                _:fsc-empty?
                _:fsc-default
                )))

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;; The actual fusion generator implementation

;; Used only in deforest-rewrite to properly recognize the end of
;; fusable sequence.
(define-syntax-class non-fusable
  (pattern (~not (~or _:fst-syntax
                      _:fsp-syntax
                      _:fsc-syntax))))

(define (make-deforest-rewrite generate-fused-operation)
  (lambda (stx)
    (syntax-parse stx
      [((~datum thread) _0:non-fusable ...
                        p:fsp-syntax
                        ;; There can be zero transformers here:
                        t:fst-syntax ...
                        c:fsc-syntax
                        _1 ...)
       #:with fused (generate-fused-operation
                     (syntax->list #'(p t ... c))
                     stx)
       #'(thread _0 ... fused _1 ...)]
      [((~datum thread) _0:non-fusable ...
                        t1:fst-intf0
                        t:fst-syntax ...
                        c:fsc-syntax
                        _1 ...)
       #:with fused (generate-fused-operation
                     (syntax->list #'(list->cstream t1 t ... c))
                     stx)
       #'(thread _0 ... fused _1 ...)]
      [((~datum thread) _0:non-fusable ...
                        p:fsp-syntax
                        ;; Must be 1 or more transformers here:
                        t:fst-syntax ...+
                        _1 ...)
       #:with fused (generate-fused-operation
                     (syntax->list #'(p t ... cstream->list))
                     stx)
       #'(thread _0 ... fused _1 ...)]
      [((~datum thread) _0:non-fusable ...
                        f1:fst-intf0
                        f:fst-syntax ...+
                        _1 ...)
       #:with fused (generate-fused-operation
                     (syntax->list #'(list->cstream f1 f ... cstream->list))
                     stx)
       #'(thread _0 ... fused _1 ...)]
      ;; return the input syntax unchanged if no rules
      ;; are applicable
      [_ stx])))

(define-syntax (define-and-register-deforest-pass stx)
  (syntax-parse stx
    ((_ (deforest-pass ops ctx) expr ...)
     #'(define-and-register-pass 100 (deforest-pass stx)
         (find-and-map/qi
          (make-deforest-rewrite
           (lambda (ops ctx)
             expr ...))
          stx)))))
