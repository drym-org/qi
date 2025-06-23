#lang racket/base

(provide define-qi-syntax
         define-qi-syntax-rule
         define-core-qi-syntax-rule
         define-qi-syntax-parser
         define-core-qi-syntax-parser
         define-qi-foreign-syntaxes
         define-deforestable
         (for-syntax qi-macro))

(require (for-syntax racket/base
                     racket/format
                     racket/match
                     racket/list)
         (only-in "flow/extended/expander.rkt"
                  qi-macro
                  esc
                  #%deforestable)
         qi/flow/space
         (for-syntax qi/flow/aux-syntax)
         syntax/parse/define
         syntax/parse
         syntax-spec-v2)

(begin-for-syntax

  (define (foreign-template-arg-indices tmpl)
    ;; return a list of indices corresponding to
    ;; argument positions indicated in the template
    ;; tmpl resembles #'(mac a _ b _ c) -- a
    ;; list-structured syntax object.
    ;; here the result would be '(1 3)
    (let ([arg-tmpl (cdr (syntax->list tmpl))])
      (let loop ([arg-tmpl arg-tmpl]
                 [i 0])
        (match arg-tmpl
          ['() null]
          [(cons v vs) (if (eq? '_ (syntax-e v))
                           (cons i (loop vs (add1 i)))
                           (loop vs (add1 i)))]))))

  (define (foreign-macro-render-template tmpl args)
    ;; accept a template (a list-structured syntax object)
    ;; and a list of unique argument names, and populate the
    ;; blanks in the template with those arguments
    ;; wrapped in a lambda
    #`(esc
       (lambda #,args
         #,(datum->syntax
               tmpl
             (let loop ([tmpl (syntax->list tmpl)]
                        [args args])
               (if (null? args)
                   tmpl
                   (match-let ([(cons arg rem-args) args]
                               [(cons v vs) tmpl])
                     (if (eq? '_ (syntax-e v))
                         (cons arg (loop vs rem-args))
                         (cons v (loop vs args))))))))))

  (define (foreign-macro-template-expand tmpl)
    ;; e.g. (foreign-macro-template-expand #'(mac a _ b _ c))
    (let* ([indices (foreign-template-arg-indices tmpl)])
      (foreign-macro-render-template
       tmpl
       (generate-temporaries (make-list (length indices) '_)))))

  (define (make-qi-foreign-syntax-transformer original-macro-id)
    (define/syntax-parse original-macro original-macro-id)
    (syntax-parser
      [(name pre-form ... (~datum __) post-form ...)
       (let ([name (syntax->datum #'name)])
         (raise-syntax-error name
                             (~a "Syntax error in "
                                 `(,name
                                   ,@(syntax->datum #'(pre-form ...))
                                   "__"
                                   ,@(syntax->datum #'(post-form ...)))
                                 "\n"
                                 "  __ templates are not supported for foreign macros.\n"
                                 "  Use _'s to indicate a specific number of expected arguments, instead.")))]
      [(name pre-form ... (~datum _) post-form ...)
       (foreign-macro-template-expand
        (datum->syntax this-syntax
          (cons #'original-macro
                (cdr (syntax->list this-syntax)))))]
      [(name form ...)
       #:do [(define chirality (syntax-property this-syntax 'chirality))]
       (if (and chirality (eq? chirality 'right))
           #'(esc (lambda (v) (original-macro form ... v)))
           #'(esc (lambda (v) (original-macro v form ...))))]
      [name:id #'(esc (lambda (v) (original-macro v)))])))

(define-syntax define-qi-syntax-rule
  (syntax-parser
    [(_ (name . pat) template)
     #'(define-dsl-syntax name qi-macro
         (syntax-parser
           [(_ . pat) #'template]))]))

(define-syntax define-core-qi-syntax-rule
  (syntax-parser
    [(_ (name . pat) template)
     #'(define-qi-syntax name
         (qi-macro
          (syntax-parser
            [(_ . pat) (syntax/loc this-syntax
                         template)])))]))

(begin-for-syntax

  (define (source-location-contained? inner outer)
    (and (equal? (syntax-source inner)
                 (syntax-source outer))
         (>= (syntax-position inner)
             (syntax-position outer))
         (<= (+ (syntax-position inner)
                (syntax-span inner))
             (+ (syntax-position outer)
                (syntax-span outer)))))

  ;; Example: (and g) → g
  ;; This would naively highlight (and g), but in this case
  ;; we want to highlight g instead. So, we check whether
  ;; one expression is contained in the other, and if so,
  ;; keep the srcloc of the inner one, to handle this.
  (define (propagate-syntax-loc f)
    (λ (stx)
      (let ([res (f stx)])
        (datum->syntax res  ; lexical context
          ;; datum
          (syntax-e res)
          ;; for srcloc
          (if (source-location-contained? res stx)
              res
              stx)
          ;; for properties
          res)))))

(define-syntax define-qi-syntax-parser
  (syntax-parser
    [(_ name clause ...)
     #'(define-dsl-syntax name qi-macro
         (syntax-parser
           clause ...))]))

(define-syntax define-core-qi-syntax-parser
  (syntax-parser
    [(_ name clause ...)
     #'(define-qi-syntax name
         (qi-macro
          (propagate-syntax-loc
           (syntax-parser
             clause ...))))]))

(define-syntax define-qi-foreign-syntaxes
  (syntax-parser
    [(_ form-name ...)
     #'(begin
         (define-dsl-syntax form-name qi-macro
           (make-qi-foreign-syntax-transformer #'form-name))
         ...)]))

(begin-for-syntax
  (define (op-transformer name info spec)
    ;; use the `spec` to rewrite the source expression to expand
    ;; to a corresponding number of clauses in the core form, like:
    ;; (op e1 e2 e3) → (#%optimizable-app #,info [f e1] [e e2] [f e3])
    (syntax-parse spec
      #:datum-literals (op)
      [(op [tag arg-name] ...)
       (syntax-parser
         [(_ e ...+)
          #:fail-unless (= (length (attribute e))
                           (length (attribute arg-name)))
          "Wrong number of arguments!"
          #`(#%deforestable #,name #,info [tag e] ...)]
         [_:id
          (raise-syntax-error #f
                              (format "Bad syntax. Usage: (~a arg ...)"
                                      (syntax->datum this-syntax))
                              this-syntax)])]
      [op
       (syntax-parser
         ;; already raises a good error if used as a
         ;; form with arguments (rather than as an identifier)
         ;; so no special error handling needed here
         [_:id #`(#%deforestable #,name #,info)])])))

(define-syntax define-deforestable
  (syntax-parser
    [(_ (name spec ...+) codegen)
     #:with ([_typ arg] ...) #'(spec ...)
     #:with codegen-f #'(lambda (arg ...)
                          ;; var bindings vs pattern bindings
                          ;; arg are syntax objects but we can't
                          ;; use them as variable bindings, so
                          ;; we use with-syntax to handle them
                          ;; as pattern bindings
                          (with-syntax ([arg arg] ...)
                            codegen))
     #'(begin

         ;; capture the codegen in an instance of
         ;; the compile time struct
         (define-syntax info
           (deforestable-info codegen-f))

         (define-dsl-syntax name qi-macro
           (op-transformer #'name #'info #'(op spec ...))))]
    [(_ name:id codegen)
     #:with codegen-f #'(lambda () codegen)
     #'(begin

         ;; capture the codegen in an instance of
         ;; the compile time struct
         (define-syntax info
           (deforestable-info codegen-f))

         (define-dsl-syntax name qi-macro
           (op-transformer #'name #'info #'op)))]))
