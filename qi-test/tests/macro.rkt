#lang racket/base

(provide tests)

(require qi
         rackunit
         (only-in math sqr)
         (for-syntax syntax/parse
                     racket/base)
         syntax/parse/define
         "private/util.rkt")

(define-qi-syntax-rule (square flo:expr)
  (feedback 2 flo))

(define-qi-syntax-rule (pare car-flo cdr-flo)
  (group 1 car-flo cdr-flo))

(define-qi-syntax-parser cube
  [(_ flo) #'(feedback 3 flo)])

(define-qi-syntax-rule (fanout n)
  'hello)

(define-qi-syntax-parser kazam
  [_:id #''hello])

(define-qi-syntax-rule (my-and flo ...)
  (and flo ...))

(define-qi-syntax-parser my-or
  [(_ flo ...) #'(or flo ...)])

(define-qi-syntax-parser also-or
  [(_ flo ...) #''hello])

(define-syntax-parse-rule (macreaux x y)
  y)

(define-qi-foreign-syntaxes macreaux)

(define tests
  (test-suite
   "macro tests"
   (test-suite
    "base"
    (check-equal? ((☯ (square sqr)) 2) 16)
    (check-equal? ((☯ (~> (pare sqr +) ▽)) 3 6 9) (list 9 15))
    (check-equal? ((☯ (cube sqr)) 2) 256)
    (check-equal? ((☯ (fanout 5)) 2) 'hello "extensions can override built-in forms")
    (check-equal? ((☯ kazam) 2) 'hello "extensions can add identifier macros"))

   (test-suite
    "interaction with built-in forms"
    (check-equal? (my-and 5 6) 6)
    (check-true ((☯ (my-and positive? integer?)) 5))
    (check-equal? (my-or 5 6) 5)
    (check-true ((☯ (my-or positive? integer?)) 5.2))
    (check-equal? ((☯ (also-or 1 2 3))) 'hello
                  "macro with different qi and racket expansions")
    (check-equal? (also-or 5 6) 5
                  "macro with different qi and racket expansions")
    (check-equal? ((☯ (also-and 1 2 3))) 'hello
                  "macro defined in another module and provided 'for space'")
    (check-equal? (also-and 5 6) 6
                  "macro defined in another module and provided 'for space'"))
   (test-suite
    "interaction with foreign-language macros"
    (check-equal? ((☯ (macreaux 1)) 2) 1)
    (check-equal? ((☯ (~>> (macreaux 1))) 2) 2)
    (check-equal? ((☯ (macreaux _ 1)) 2) 1)
    (check-equal? ((☯ (macreaux 1 _)) 2) 2)
    (check-exn exn:fail? (λ () ((☯ (macreaux 1 __)) 2)) 2))))
