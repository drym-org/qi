#lang racket/base

(require syntax/parse/define
         fancy-app
         adjutor
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
    (pattern
     expr:expr)))

(define-syntax-parser right-threading-clause
  [(_ onex:clause)
   (datum->syntax this-syntax
                  (list 'on-clause #'onex)
                  #f
                  (syntax-property this-syntax 'threading-side 'right))])

(define-syntax-parser conjux-clause  ; "juxtaposed" conjoin
  [(_ (~datum _)) #'true.]
  [(_ onex:clause) #'(on-clause onex)])

(define-syntax-parser disjux-clause  ; "juxtaposed" disjoin
  [(_ (~datum _)) #'false.]
  [(_ onex:clause) #'(on-clause onex)])

(define-syntax-parser channel-clause
  [(_ (~datum _)) #'identity]
  [(_ onex:clause) #'(on-clause onex)])

(define-syntax-parser pass-clause
  [(_ onex:clause return:expr)
   #'(λ args
       (if (apply (on-clause onex) args)
           (apply values args)
           ((on-clause (>< (gen return))) args)))])

(define-syntax-parser on-clause
  ;; special words
  [(_ ((~datum one-of?) v:expr ...))
   #'(compose
      ->boolean
      (curryr member (list v ...)))]
  [(_ ((~datum all) onex:clause))
   #'(give (curry andmap (on-clause onex)))]
  [(_ ((~datum any) onex:clause))
   #'(give (curry ormap (on-clause onex)))]
  [(_ ((~datum none) onex:clause))
   #'(on-clause (not (any onex)))]
  [(_ ((~datum and) onex:clause ...))
   #'(conjoin (on-clause onex) ...)]
  [(_ ((~datum or) onex:clause ...))
   #'(disjoin (on-clause onex) ...)]
  [(_ ((~datum not) onex:clause))
   #'(negate (on-clause onex))]
  [(_ ((~datum gen) ex:expr))
   #'(const ex)]
  [(_ (~or (~datum NOT) (~datum !)))
   #'not]
  [(_ (~or (~datum AND) (~datum &)))
   #'all?]
  [(_ (~or (~datum OR) (~datum ||)))
   #'any?]
  [(_ (~datum NOR))
   #'(on-clause (~> OR NOT))]
  [(_ (~datum NAND))
   #'(on-clause (~> AND NOT))]
  [(_ (~datum XOR))
   #'parity-xor]
  [(_ (~datum XNOR))
   #'(on-clause (~> XOR NOT))]
  [(_ ((~datum and%) onex:clause ...))
   #'(on-clause (~> (== (expr (conjux-clause onex)) ...)
                    all?))]
  [(_ ((~datum or%) onex:clause ...))
   #'(on-clause (~> (== (expr (disjux-clause onex)) ...)
                    any?))]
  [(_ ((~datum with-key) f:clause onex:clause))
   #'(compose
      (curry apply (on-clause onex))
      (give (curry map (on-clause f))))]
  [(_ ((~datum ..) onex:clause ...))
   #'(compose (on-clause onex) ...)]
  [(_ ((~datum compose) onex:clause ...))
   #'(on-clause (.. onex ...))]
  [(_ ((~datum ~>) onex:clause ...))
   (datum->syntax
    this-syntax
    (list 'on-clause
          (cons '..
                (reverse (syntax->list #'(onex ...))))))]
  [(_ ((~datum thread) onex:clause ...))
   #'(on-clause (~> onex ...))]
  [(_ ((~datum ~>>) onex:clause ...))
   #'(on-clause (~> (expr (right-threading-clause onex)) ...))]
  [(_ ((~datum thread-right) onex:clause ...))
   #'(on-clause (~>> onex ...))]
  [(_ (~datum any?)) #'any?]
  [(_ (~datum all?)) #'all?]
  [(_ (~datum none?)) #'none?]

  ;; routing elements
  [(_ ((~datum ><) onex:clause))
   #'(curry map-values (channel-clause onex))]
  [(_ ((~datum amp) onex:clause))
   #'(on-clause (>< onex))]
  [(_ ((~datum ==) onex:clause ...))
   #'(relay (channel-clause onex) ...)]
  [(_ ((~datum relay) onex:clause ...))
   #'(on-clause (== onex ...))]
  [(_ ((~datum -<) onex:clause ...))
   #'(λ args
       (apply values
              (append (values->list
                       (apply (channel-clause onex) args))
                      ...)))]
  [(_ ((~datum tee) onex:clause ...))
   #'(on-clause (-< onex ...))]
  [(_ ((~datum select) n:number ...))
   #'(on-clause (-< (expr (arg n)) ...))]
  [(_ ((~datum group) n:number
                      selection-onex:clause
                      remainder-onex:clause))
   #`(loom-compose (on-clause selection-onex)
                   (on-clause remainder-onex)
                   n)]
  [(_ ((~datum pass) onex:clause
                     (~optional return:expr
                                #:defaults ([return #'#f]))))
   #'(pass-clause onex return)]
  [(_ (~datum ground))
   #'(on-clause (select))]

  ;; high level circuit elements
  [(_ ((~datum splitter) n:number))
   (datum->syntax
    this-syntax
    (list 'on-clause
          (cons '-<
                (repeat (syntax->datum #'n)
                        '_))))]
  [(_ ((~datum feedback) onex:clause n:number))
   (datum->syntax
    this-syntax
    (list 'on-clause
          (cons '~>
                (repeat (syntax->datum #'n)
                        #'onex))))]
  [(_ (~datum inverter))
   #'(on-clause (>< NOT))]

  ;; escape hatch for racket expressions or anything
  ;; to be "passed through"
  [(_ ((~datum expr) ex:expr ...))
   #'(begin ex ...)]

  ;; templates and partial application
  ;; "prarg" = "pre-supplied argument"
  [(_ (onex prarg-pre ... (~datum __) prarg-post ...))
   #'(curry (curryr (on-clause onex)
                    prarg-post ...)
            prarg-pre ...)]
  [(_ (onex prarg-pre ... (~datum _) prarg-post ...))
   #'((on-clause onex) prarg-pre ...
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
       #'(curry (on-clause onex) prarg ...)
       #'(curryr (on-clause onex) prarg ...))]

  ;; literally indicated function identifier
  [(_ ex:expr) #'ex])
