#lang racket/base

(provide tests)

(require qi
         rackunit
         rackunit/text-ui
         (only-in math sqr))


(define tests

  (test-suite
   "definition forms"

   (test-suite
    "define-flow"
    (check-equal? (let ()
                    (define-flow my-flow (~> sqr add1))
                    (my-flow 5))
                  26)
    (check-equal? (let ()
                    (define-flow (my-flow2 v) (~> (gen v) add1))
                    (my-flow2 5))
                  6)
    (check-equal? (let ()
                    (define-flow ((t n) . n*)
                      (~>> (memq n)))
                    (list ((t 3) 1 2 3)
                          ((t 0) 1 2 3)))
                  '((3) #f)))

   (test-suite
    "define-switch"
    (check-equal? (let ()
                    (define-switch my-switch
                      [positive? add1]
                      [else sub1])
                    (my-switch 5))
                  6)
    (check-equal? (let ()
                    (define-switch (my-switch2 v w)
                      [< (~> X -)]
                      [else -])
                    (my-switch2 5 6))
                  1)
    (check-equal? (let ()
                    (define-switch ((t n) . n*)
                      [(memq n _) 'yes]
                      [else 'no])
                    (list ((t 1) 1 2 3)
                          ((t 0) 1 2 3)))
                  '(yes no)))

   (test-suite
    "let/flow"
    (check-equal? (let/flow ([x 5] [y 3]) (~> + sqr add1)) 65)
    (check-equal? (let/flow my-flow2 ([v 5]) (~> (gen v) add1)) 6))

   (test-suite
    "let/switch"
    (check-equal? (let/switch ([x 5] [y 3])
                     [(~> + (> 10)) 'hi]
                     [else 'bye])
                  'bye)
    (check-equal? (let/switch my-switch2 ([v 5] [w 6])
                     [< (~> X -)]
                     [else -])
                  1))

   (test-suite
    "predicate lambda"
    (check-true ((π (x)
                   (and positive? integer?))
                 5))
    (check-false ((π (x)
                    (and positive? integer?))
                  -5))
    (check-false ((π (x)
                    (and positive? integer?))
                  5.3))
    (check-true ((π (x y)
                   (or < =))
                 5 6))
    (check-true ((π (x y)
                   (or < =))
                 5 5))
    (check-false ((π (x y)
                    (or < =))
                  5 4))
    (check-true ((π (x) (and (> 5) (< 10))) 7))
    (check-false ((π (x) (and (> 5) (< 10))) 2))
    (check-false ((π (x) (and (> 5) (< 10))) 12))
    (check-true ((π args list?) 1 2 3) "packed args")
    (check-false ((π args (~> length (> 3))) 1 2 3) "packed args")
    (check-true ((π args (~> length (> 3))) 1 2 3 4) "packed args")
    (check-false ((π args (apply > _)) 1 2 3) "apply with packed args")
    (check-true ((π args (apply > _)) 3 2 1) "apply with packed args")
    (check-equal? ((π a* _) 1 2 3 4) '(1 2 3 4))
    (check-equal? ((π (a . a*) list) 1 2 3 4) '(1 (2 3 4))))

   (test-suite
    "switch lambda"
    (check-equal? ((switch-lambda (x)
                     [(and positive? integer?) 'a])
                   5)
                  'a)
    (check-equal? ((switch-lambda (x)
                     [(and positive? integer?) 'a]
                     [else 'b])
                   -5)
                  'b)
    (check-equal? ((switch-lambda (x)
                     [(and positive? integer?) 'a]
                     [else 'b])
                   5.3)
                  'b)
    (check-equal? ((switch-lambda (x y)
                     [(or < =) 'a])
                   5 6)
                  'a)
    (check-equal? ((switch-lambda (x y)
                     [(or < =) 'a])
                   5 5)
                  'a)
    (check-equal? ((switch-lambda (x y)
                     [(or < =) 'a]
                     [else 'b])
                   5 4)
                  'b)
    (check-equal? ((λ01 args [list? 'a]) 1 2 3) 'a)
    (check-equal? ((λ01 args
                        [(~> length (> 3)) 'a]
                        [else 'b]) 1 2 3)
                  'b
                  "packed args")
    (check-equal? ((λ01 args
                        [(~> length (> 3)) 'a]
                        [else 'b]) 1 2 3 4)
                  'a
                  "packed args")
    (check-equal? ((λ01 args
                        [(apply < _) 'a]
                        [else 'b]) 1 2 3)
                  'a
                  "apply with packed args")
    (check-equal? ((λ01 args
                        [(apply < _) 'a]
                        [else 'b]) 1 3 2)
                  'b
                  "apply with packed args")
    (check-equal? ((λ01 a*
                        [list? _]
                        [else 'no])
                   1 2 3 4)
                  '(1 2 3 4))
    (check-equal? ((λ01 (a . a*)
                        [memq 'yes]
                        [else 'no])
                   2 2 3 4)
                  'yes))))

(module+ main
  (void (run-tests tests)))
