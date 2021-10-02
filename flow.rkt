#lang racket/base

(provide flow
         ☯
         (for-syntax subject
                     clause))

(require syntax/parse/define
         fancy-app
         (only-in adjutor
                  values->list)
         racket/function
         racket/format
         mischief/shorthand
         (for-syntax racket/base
                     syntax/parse))

(require "private/util.rkt")

(begin-for-syntax
  (define (repeat n v)
    (if (= 0 n)
        null
        (cons v (repeat (sub1 n) v))))

  (define-syntax-class literal
    (pattern
     (~or expr:boolean
          expr:char
          expr:string
          expr:bytes
          expr:number
          expr:regexp
          expr:byte-regexp)))

  (define-syntax-class subject
    #:attributes (args arity)
    (pattern
     (arg:expr ...)
     #:with args #'(arg ...)
     #:attr arity (length (syntax->list #'args))))

  (define-syntax-class clause
    (pattern
     expr:expr)))

(define-alias ☯ flow)

(define-syntax-parser right-threading-clause
  [(_ onex:clause)
   (datum->syntax this-syntax
                  (list 'flow #'onex)
                  #f
                  (syntax-property this-syntax 'threading-side 'right))])

(define-syntax-parser conjux-clause  ; "juxtaposed" conjoin
  [(_ (~datum _)) #'true.]
  [(_ onex:clause) #'(flow onex)])

(define-syntax-parser disjux-clause  ; "juxtaposed" disjoin
  [(_ (~datum _)) #'false.]
  [(_ onex:clause) #'(flow onex)])

#|
A note on error handling:

The `flow` macro specifies the forms of the DSL. Some forms, in
addition to handling legitimate syntax, also have catch-all versions
that exist purely to provide a helpful message indicating a syntax
error. We do this since a priori the macro would ignore syntax that
doesn't match the pattern. Yet, for all of these named forms, we know
that (or at least, it is prudent to assume that) the user intended to
employ that particular form of the DSL. So instead of allowing it to
fall through for interpretation as Racket code, which would yield
potentially inscrutable errors, the catch-all forms allow us to
provide appropriate error messages at the level of the DSL.

|#

(define (report-syntax-error name args msg)
  (raise-syntax-error name
                      (~a "Syntax error in "
                          (list* name args)
                          "\n"
                          "Usage:\n"
                          "  " msg)))

(define-syntax-parser flow
  ;; special words
  [(_ ((~datum one-of?) v:expr ...))
   #'(compose
      ->boolean
      (curryr member (list v ...)))]
  [(_ ((~datum all) onex:clause))
   #'(give (curry andmap (flow onex)))]
  [(_ ((~datum any) onex:clause))
   #'(give (curry ormap (flow onex)))]
  [(_ ((~datum none) onex:clause))
   #'(flow (not (any onex)))]
  [(_ ((~datum and) onex:clause ...))
   #'(conjoin (flow onex) ...)]
  [(_ ((~datum or) onex:clause ...))
   #'(disjoin (flow onex) ...)]
  [(_ ((~datum not) onex:clause))
   #'(negate (flow onex))]
  [(_ ((~datum gen) ex:expr ...))
   #'(λ _ (values ex ...))]
  [(_ (~or (~datum NOT) (~datum !)))
   #'not]
  [(_ (~or (~datum AND) (~datum &)))
   #'all?]
  [(_ (~or (~datum OR) (~datum ||)))
   #'any?]
  [(_ (~datum NOR))
   #'(flow (~> OR NOT))]
  [(_ (~datum NAND))
   #'(flow (~> AND NOT))]
  [(_ (~datum XOR))
   #'parity-xor]
  [(_ (~datum XNOR))
   #'(flow (~> XOR NOT))]
  [(_ ((~datum and%) onex:clause ...))
   #'(flow (~> (== (esc (conjux-clause onex)) ...)
               all?))]
  [(_ ((~datum or%) onex:clause ...))
   #'(flow (~> (== (esc (disjux-clause onex)) ...)
               any?))]
  [(_ ((~datum with-key) f:clause onex:clause))
   #'(compose
      (curry apply (flow onex))
      (give (curry map (flow f))))]
  [(_ ((~datum ..) onex:clause ...))
   #'(compose (flow onex) ...)]
  [(_ ((~datum compose) onex:clause ...))
   #'(flow (.. onex ...))]
  [(_ ((~datum ~>) onex:clause ...))
   (datum->syntax
    this-syntax
    (list 'flow
          (cons '..
                (reverse (syntax->list #'(onex ...))))))]
  [(_ ((~datum thread) onex:clause ...))
   #'(flow (~> onex ...))]
  [(_ ((~datum ~>>) onex:clause ...))
   #'(flow (~> (esc (right-threading-clause onex)) ...))]
  [(_ ((~datum thread-right) onex:clause ...))
   #'(flow (~>> onex ...))]
  [(_ (~datum any?)) #'any?]
  [(_ (~datum all?)) #'all?]
  [(_ (~datum none?)) #'none?]

  ;; routing elements
  [(_ ((~datum ><) onex:clause))
   #'(curry map-values (flow onex))]
  [(_ ((~datum amp) onex:clause))
   #'(flow (>< onex))]
  [(_ ((~datum pass) onex:clause))
   #'(curry filter-values (flow onex))]
  [(_ ((~datum ==) onex:clause ...))
   #'(relay (flow onex) ...)]
  [(_ ((~datum relay) onex:clause ...))
   #'(flow (== onex ...))]
  [(_ ((~datum -<) onex:clause ...))
   #'(λ args
       (apply values
              (append (values->list
                       (apply (flow onex) args))
                      ...)))]
  [(_ ((~datum tee) onex:clause ...))
   #'(flow (-< onex ...))]
  [(_ ((~datum select) n:number ...))
   #'(flow (-< (esc (arg n)) ...))]
  [(_ ((~datum select) arg ...))  ; error handling catch-all
   #'(report-syntax-error 'select
                          (list 'arg ...)
                          "(select <number> ...)")]
  [(_ ((~datum group) n:number
                      selection-onex:clause
                      remainder-onex:clause))
   #'(loom-compose (flow selection-onex)
                   (flow remainder-onex)
                   n)]
  [(_ ((~datum group) arg ...))  ; error handling catch-all
   #'(report-syntax-error 'group
                          (list 'arg ...)
                          "(group <number> <selection flow> <remainder flow>)")]
  [(_ ((~datum sieve) condition:clause
                      selection-onex:clause
                      remainder-onex:clause))
   ;; this is equivalent to "channel-clause", but done via with-syntax
   ;; so it's usable in the syntax (expansion) phase
   (with-syntax ([sonex (if (eq? '_ (syntax->datum #'selection-onex))
                            (datum->syntax #'selection-onex #'values)
                            #'selection-onex)]
                 [ronex (if (eq? '_ (syntax->datum #'remainder-onex))
                            (datum->syntax #'remainder-onex #'values)
                            #'remainder-onex)])
     #'(flow (-< (~> (pass condition) sonex)
                 (~> (pass (not condition)) ronex))))]
  [(_ ((~datum sieve) arg ...))  ; error handling catch-all
   #'(report-syntax-error 'sieve
                          (list 'arg ...)
                          "(sieve <predicate flow> <selection flow> <remainder flow>)")]
  [(_ ((~datum if) condition:clause
                   consequent:clause
                   alternative:clause))
   #'(λ args
       (if (apply (flow condition) args)
           (apply (flow consequent) args)
           (apply (flow alternative) args)))]
  [(_ ((~datum switch)))
   #'(flow ground)]
  [(_ ((~datum switch) [(~datum else) alternative:clause]))
   #'(flow (if #t
               alternative
               ground))]
  [(_ ((~datum switch) [condition0:clause consequent0:clause]
                       [condition:clause consequent:clause]
                       ...))
   #'(flow (if condition0
               consequent0
               (switch [condition consequent]
                 ...)))]
  [(_ ((~datum gate) onex:clause))
   #'(flow (if onex _ ground))]
  [(_ (~or (~datum ground) (~datum ⏚)))
   #'(flow (select))]

  ;; high level circuit elements
  [(_ ((~datum fanout) n:number))
   (datum->syntax
    this-syntax
    (list 'flow
          (cons '-<
                (repeat (syntax->datum #'n)
                        '_))))]
  [(_ ((~datum feedback) onex:clause n:number))
   (datum->syntax
    this-syntax
    (list 'flow
          (cons '~>
                (repeat (syntax->datum #'n)
                        #'onex))))]
  [(_ (~datum inverter))
   #'(flow (>< NOT))]
  [(_ ((~or (~datum effect) (~datum ε)) sidex:clause onex:clause))
   #'(flow (-< (~> sidex ground)
               onex))]
  [(_ ((~datum collect) onex:clause))
   #'(flow (~> list onex))]

  ;; escape hatch for racket expressions or anything
  ;; to be "passed through"
  [(_ ((~datum esc) ex:expr ...))
   #'(begin ex ...)]

  ;; templates and partial application
  ;; "prarg" = "pre-supplied argument"
  [(_ (onex prarg-pre ... (~datum __) prarg-post ...))
   #'(curry (curryr (flow onex)
                    prarg-post ...)
            prarg-pre ...)]
  [(_ (onex prarg-pre ... (~datum _) prarg-post ...))
   #'((flow onex) prarg-pre ...
                  _
                  prarg-post ...)]
  [(_ (onex prarg ...))
   ;; we use currying instead of templates when a template hasn't
   ;; explicitly been indicated since in such cases, we cannot
   ;; always infer the appropriate arity for a template (e.g. it
   ;; may change under composition within the form), while a
   ;; curried function will accept any number of arguments
   #:do [(define threading-side (syntax-property this-syntax 'threading-side))]
   (if (and threading-side (eq? threading-side 'right))
       #'(curry (flow onex) prarg ...)
       #'(curryr (flow onex) prarg ...))]

  ;; a literal should be interpreted as a flow generating it
  [(_ val:literal) #'(flow (gen val))]

  ;; pass-through (identity flow)
  [(_ (~datum _)) #'values]

  ;; literally indicated function identifier
  [(_ ex:expr) #'ex]

  ;; a non-flow
  [(_) #'void])
