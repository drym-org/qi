#lang racket/base

(provide fusable-stream-producer
         fsp-range
         fsp-default

         fusable-stream-transformer
         fst-filter
         fst-map
         fst-filter-map
         fst-take

         fusable-stream-consumer
         fsc-foldr
         fsc-foldl
         fsc-list-ref
         fsc-length
         fsc-empty?
         fsc-default

         define-and-register-deforest-pass
         )

(require syntax/parse
         "passes.rkt"
         "strategy.rkt"
         (for-template racket/base
                       "passes.rkt"
                       "strategy.rkt"
                       "deforest-templates.rkt")
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
  #:datum-literals (range)
  (pattern (esc (#%host-expression range))
           #:attr arg #f
           #:attr pre-arg #f
           #:attr post-arg #f
           #:attr blanket? #f
           #:attr fine? #f)
  (pattern (#%fine-template
            ((#%host-expression range)
             the-arg ...))
           #:attr arg #'(the-arg ...)
           #:attr pre-arg #f
           #:attr post-arg #f
           #:attr blanket? #f
           #:attr fine? #t)
  (pattern (#%blanket-template
            ((#%host-expression range)
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

(define-syntax-class fusable-stream-producer
  (pattern (~or range:fsp-range
                default:fsp-default)))

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;; Transformers

(define-syntax-class fst-filter
  #:attributes (f)
  #:datum-literals (#%host-expression #%blanket-template __ _ #%fine-template filter)
  (pattern (~or (#%blanket-template
                 ((#%host-expression filter)
                  (#%host-expression f)
                  __))
                (#%fine-template
                 ((#%host-expression filter)
                  (#%host-expression f)
                  _)))))

(define-syntax-class fst-map
  #:attributes (f)
  #:datum-literals (#%host-expression #%blanket-template __ _ #%fine-template map)
  (pattern (~or (#%blanket-template
                 ((#%host-expression map)
                  (#%host-expression f)
                  __))
                (#%fine-template
                 ((#%host-expression map)
                  (#%host-expression f)
                  _)))))

(define-syntax-class fst-filter-map
  #:attributes (f)
  #:datum-literals (#%host-expression #%blanket-template __ _ #%fine-template filter-map)
  (pattern (~or (#%blanket-template
                 ((#%host-expression filter-map)
                  (#%host-expression f)
                  __))
                (#%fine-template
                 ((#%host-expression filter-map)
                  (#%host-expression f)
                  _)))))

(define-syntax-class fst-take
  #:attributes (n)
  #:datum-literals (#%host-expression #%blanket-template __ _ #%fine-template take)
  (pattern (~or (#%blanket-template
                 ((#%host-expression take)
                  __
                  (#%host-expression n)))
                (#%fine-template
                 ((#%host-expression take)
                  _
                  (#%host-expression n))))))

(define-syntax-class fusable-stream-transformer0
  (pattern (~or filter:fst-filter
                filter-map:fst-filter-map)))

(define-syntax-class fusable-stream-transformer
  (pattern (~or filter:fst-filter
                map:fst-map
                filter-map:fst-filter-map
                take:fst-take)))

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;; Consumers

(define-syntax-class fsc-foldr
  #:attributes (op init)
  #:datum-literals (#%host-expression #%blanket-template __ _ #%fine-template foldr)
  (pattern (~or (#%blanket-template
                 ((#%host-expression foldr)
                  (#%host-expression op)
                  (#%host-expression init)
                  __))
                (#%fine-template
                 ((#%host-expression foldr)
                  (#%host-expression op)
                  (#%host-expression init)
                  _)))))

(define-syntax-class fsc-foldl
  #:attributes (op init)
  #:datum-literals (#%host-expression #%blanket-template __ _ #%fine-template foldl)
  (pattern (~or (#%blanket-template
                 ((#%host-expression foldl)
                  (#%host-expression op)
                  (#%host-expression init)
                  __))
                (#%fine-template
                 ((#%host-expression foldl)
                  (#%host-expression op)
                  (#%host-expression init)
                  _)))))

(define-syntax-class cad*r-datum
  #:attributes (countdown)
  (pattern (~datum car) #:attr countdown #'0)
  (pattern (~datum cadr) #:attr countdown #'1)
  (pattern (~datum caddr) #:attr countdown #'2)
  (pattern (~datum cadddr) #:attr countdown #'3)
  (pattern (~datum caddddr) #:attr countdown #'4)
  (pattern (~datum cadddddr) #:attr countdown #'5))

(define-syntax-class fsc-list-ref
  #:attributes (pos name)
  #:datum-literals (#%host-expression #%blanket-template __ _ #%fine-template list-ref)
  (pattern (~or (#%fine-template
                 ((#%host-expression list-ref) _ idx))
                (#%blanket-template
                 ((#%host-expression list-ref) __ idx)))
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
  #:datum-literals (#%host-expression #%blanket-template __ _ #%fine-template length)
  (pattern (~or (esc
                 (#%host-expression length))
                (#%fine-template
                 ((#%host-expression length) _))
                (#%blanket-template
                 ((#%host-expression length) __)))))

(define-syntax-class fsc-empty?
  #:datum-literals (#%host-expression #%blanket-template __ _ #%fine-template empty? null?)
  (pattern (~or (esc
                 (#%host-expression (~or empty?
                                         null?)))
                (#%fine-template
                 ((#%host-expression (~or empty?
                                          null?)) _))
                (#%blanket-template
                 ((#%host-expression (~or empty?
                                          null?)) __)))))

(define-syntax-class fsc-default
  #:datum-literals (#%host-expression #%blanket-template __ _ #%fine-template cstream->list)
  (pattern cstream->list))

(define-syntax-class fusable-stream-consumer
  (pattern (~or foldr:fsc-foldr
                foldl:fsc-foldl
                list-ref:fsc-list-ref
                lenght:fsc-length
                empty?:fsc-empty?
                default:fsc-default
                )))

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;; The actual fusion generator implementation

;; Used only in deforest-rewrite to properly recognize the end of
;; fusable sequence.
(define-syntax-class non-fusable
  (pattern (~not (~or _:fusable-stream-transformer
                      _:fusable-stream-producer
                      _:fusable-stream-consumer))))

(define (make-deforest-rewrite generate-fused-operation)
  (lambda (stx)
    (syntax-parse stx
      [((~datum thread) _0:non-fusable ...
                        p:fusable-stream-producer
                        ;; There can be zero transformers here:
                        t:fusable-stream-transformer ...
                        c:fusable-stream-consumer
                        _1 ...)
       #:with fused (generate-fused-operation
                     (syntax->list #'(p t ... c))
                     stx)
       #'(thread _0 ... fused _1 ...)]
      [((~datum thread) _0:non-fusable ...
                        t1:fusable-stream-transformer0
                        t:fusable-stream-transformer ...
                        c:fusable-stream-consumer
                        _1 ...)
       #:with fused (generate-fused-operation
                     (syntax->list #'(list->cstream t1 t ... c))
                     stx)
       #'(thread _0 ... fused _1 ...)]
      [((~datum thread) _0:non-fusable ...
                        p:fusable-stream-producer
                        ;; Must be 1 or more transformers here:
                        t:fusable-stream-transformer ...+
                        _1 ...)
       #:with fused (generate-fused-operation
                     (syntax->list #'(p t ... cstream->list))
                     stx)
       #'(thread _0 ... fused _1 ...)]
      [((~datum thread) _0:non-fusable ...
                        f1:fusable-stream-transformer0
                        f:fusable-stream-transformer ...+
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
