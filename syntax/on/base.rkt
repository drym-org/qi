#lang racket/base

(require syntax/parse/define
         fancy-app
         racket/function
         (for-syntax racket/base
                     syntax/parse))

(require "private/util.rkt")

(provide on-clause
         (for-syntax subject
                     clause))

(begin-for-syntax
  (define (repeat n v)
    (if (= 0 n)
        null
        (cons v (repeat (sub1 n) v))))

  (define-syntax-class subject
    #:attributes (args arity)
    (pattern
     (arg:expr ...)
     #:with args #'(arg ...)
     #:attr arity (length (syntax->list #'args))))

  (define-syntax-class clause
    #:attributes (is-template)
    (pattern
     expr:expr
     #:attr is-template (and (syntax->list #'expr)
                             (or (member '_ (syntax->datum #'expr))
                                 (member '__ (syntax->datum #'expr)))))))

(define-syntax-parser right-threading-clause
  [(_ onex:clause arity:number)
   (datum->syntax this-syntax
                  (list 'on-clause #'onex #'arity)
                  #f
                  (syntax-property this-syntax 'threading-side 'right))])

(define-syntax-parser conjux-clause  ; "juxtaposed" conjoin
  [(_ (~datum _) arity:number) #'true.]
  [(_ onex:clause arity:number) #'(on-clause onex arity)])

(define-syntax-parser disjux-clause  ; "juxtaposed" disjoin
  [(_ (~datum _) arity:number) #'false.]
  [(_ onex:clause arity:number) #'(on-clause onex arity)])

(define-syntax-parser channel-clause
  [(_ (~datum _) arity:number) #'identity]
  [(_ onex:clause arity:number) #'(on-clause onex arity)])

(define-syntax-parser pass-clause
  [(_ onex:clause return:expr arity:number)
   #`(λ args
       (if (apply (on-clause onex arity) args)
           (apply values args)
           (values #,@(repeat (syntax->datum #'arity) #'return))))])

(define-syntax-parser on-clause
  ;; special words
  [(_ ((~datum one-of?) v:expr ...) arity:number)
   #'(compose
      ->boolean
      (curryr member (list v ...)))]
  [(_ ((~datum all) onex:clause) arity:number)
   #'(give (curry andmap (on-clause onex arity)))]
  [(_ ((~datum any) onex:clause) arity:number)
   #'(give (curry ormap (on-clause onex arity)))]
  [(_ ((~datum none) onex:clause) arity:number)
   #'(on-clause (not (any onex)) arity)]
  [(_ ((~datum and) onex:clause ...) arity:number)
   #'(conjoin (on-clause onex arity) ...)]
  [(_ ((~datum or) onex:clause ...) arity:number)
   #'(disjoin (on-clause onex arity) ...)]
  [(_ ((~datum not) onex:clause) arity:number)
   #'(negate (on-clause onex arity))]
  [(_ ((~datum gen) ex:expr) arity:number)
   #'(const ex)]
  [(_ (~or (~datum NOT) (~datum !)) arity:number)
   #'not]
  [(_ (~or (~datum AND) (~datum &)) arity:number)
   #'all?]
  [(_ (~or (~datum OR) (~datum ||)) arity:number)
   #'any?]
  [(_ (~datum NOR) arity:number)
   #'(on-clause (~> OR NOT) arity)]
  [(_ (~datum NAND) arity:number)
   #'(on-clause (~> AND NOT) arity)]
  [(_ (~datum XOR) arity:number)
   #'parity-xor]
  [(_ (~datum XNOR) arity:number)
   #'(on-clause (~> XOR NOT) arity)]
  [(_ ((~datum and%) onex:clause ...) arity:number)
   #'(on-clause (~> (== (expr (conjux-clause onex 1)) ...)
                    all?)
                arity)]
  [(_ ((~datum or%) onex:clause ...) arity:number)
   #'(on-clause (~> (== (expr (disjux-clause onex 1)) ...)
                    any?)
                arity)]
  [(_ ((~datum with-key) f:clause onex:clause) arity:number)
   #'(compose
      (curry apply (on-clause onex arity))
      (give (curry map (on-clause f arity))))]
  [(_ ((~datum ..) onex:clause ...) arity:number)
   #'(compose (on-clause onex arity) ...)]
  [(_ ((~datum compose) onex:clause ...) arity:number)
   #'(on-clause (.. onex ...) arity)]
  [(_ ((~datum ~>) onex:clause ...) arity:number)
   (datum->syntax
    this-syntax
    (cons 'on-clause
          (list (cons '..
                      (reverse (syntax->list #'(onex ...))))
                #'arity)))]
  [(_ ((~datum thread) onex:clause ...) arity:number)
   #'(on-clause (~> onex ...) arity)]
  [(_ ((~datum ~>>) onex:clause ...) arity:number)
   #'(on-clause (~> (expr (right-threading-clause onex arity)) ...) arity)]
  [(_ ((~datum thread-right) onex:clause ...) arity:number)
   #'(on-clause (~>> onex ...) arity)]
  [(_ (~datum any?) arity:number) #'any?]
  [(_ (~datum all?) arity:number) #'all?]
  [(_ (~datum none?) arity:number) #'none?]

  ;; routing elements
  [(_ ((~datum ><) onex:clause) arity:number)
   #'(curry map-values (channel-clause onex 1))]
  [(_ ((~datum amp) onex:clause) arity:number)
   #'(on-clause (>< onex) arity)]
  [(_ ((~datum ==) onex:clause ...) arity:number)
   #'(relay (channel-clause onex 1) ...)]
  [(_ ((~datum relay) onex:clause ...) arity:number)
   #'(on-clause (== onex ...) arity)]
  [(_ ((~datum -<) onex:clause ...) arity:number)
   #'(λ args (values (apply (channel-clause onex arity) args) ...))]
  [(_ ((~datum tee) onex:clause ...) arity:number)
   #'(on-clause (-< onex ...) arity)]
  [(_ ((~datum select) n:number ...) arity:number)
   #'(on-clause (-< (expr (arg n)) ...) arity)]
  [(_ ((~datum group) n:number
                      selection-onex:clause
                      remainder-onex:clause)
      arity:number)
   #`(loom-compose (on-clause selection-onex n)
                   (on-clause remainder-onex #,(- (syntax->datum #'arity)
                                                  (syntax->datum #'n)))
                   n)]
  [(_ ((~datum pass) onex:clause
                     (~optional return:expr
                                #:defaults ([return #'#f])))
      arity:number)
   #'(pass-clause onex return arity)]

  ;; high level circuit elements
  [(_ ((~datum splitter) n:number) arity:number)
   (datum->syntax
    this-syntax
    (cons 'on-clause
          (list (cons '-<
                      (repeat (syntax->datum #'n)
                              '_))
                #'arity)))]
  [(_ ((~datum feedback) onex:clause n:number) arity:number)
   (datum->syntax
    this-syntax
    (cons 'on-clause
          (list (cons '~>
                      (repeat (syntax->datum #'n)
                              #'onex))
                #'arity)))]
  [(_ (~datum inverter) arity:number)
   #'(on-clause (>< NOT) arity)]

  ;; escape hatch for racket expressions or anything
  ;; to be "passed through"
  [(_ ((~datum expr) ex:expr ...) arity:number)
   #'(begin ex ...)]

  ;; templates and default to partial application
  ;; "prarg" = "pre-supplied argument"
  [(_ (onex prarg-pre ... (~datum __) prarg-post ...) arity:number)
   #`((on-clause onex arity) prarg-pre ...
                             #,@(repeat (syntax->datum #'arity) #'_)
                             prarg-post ...)]
  [(_ (onex prarg-pre ... (~datum _) prarg-post ...) arity:number)
   #'((on-clause onex arity) prarg-pre ...
                             _
                             prarg-post ...)]
  [(_ (onex prarg ...) arity:number)
   ;; we use currying instead of templates when a template hasn't
   ;; explicitly been indicated since in such cases, we cannot
   ;; always infer the appropriate arity for a template (e.g. it
   ;; may change under composition within the form), while a
   ;; curried function will accept any number of arguments
   #:do [(define threading-side (syntax-property this-syntax 'threading-side))]
   (if (and threading-side (eq? threading-side 'right))
       #'(curry (on-clause onex arity) prarg ...)
       #'(curryr (on-clause onex arity) prarg ...))]

  ;; literally indicated function identifier
  [(_ ex:expr arity:number) #'ex])
