#lang racket/base

(provide tests)

(require qi
         rackunit
         rackunit/text-ui
         (only-in math sqr)
         (only-in racket/function thunk)
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

(define-syntax-parse-rule (saints-macreaux x)
  (* 2 x))

(define-qi-foreign-syntaxes saints-macreaux)

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
    (check-equal? ((☯ (~>> (macreaux _ 1))) 2) 1)
    ;; note that this is a compile-time error now:
    (check-exn exn:fail:syntax?
               (thunk
                (parameterize ([current-namespace (make-base-empty-namespace)])
                  (namespace-require 'racket/base)
                  (namespace-require 'syntax/parse/define)
                  (namespace-require 'qi)
                  (eval
                   '(begin (define-syntax-parse-rule (macreaux x y) y)
                           (define-qi-foreign-syntaxes macreaux)
                           ((☯ (macreaux 1 __)) 2))
                   (current-namespace))))
               "__ template used in a foreign macro shows helpful error")
    (check-equal? ((☯ saints-macreaux) 5) 10 "can be used in identifier form")
    (check-equal? (~> (5) double-me) 10 "registered foreign syntax used in identifier form")
    (check-equal? (~> (5) (add-two 3)) 8 "registered foreign syntax using the default threading position")
    (check-equal? (~> (5) (add-two 3 _)) 8 "registered foreign syntax using a template")
    (check-equal? (~> (5 3) (add-two _ _)) 8 "registered foreign syntax threading multiple values"))))

(module+ main
  (void (run-tests tests)))
