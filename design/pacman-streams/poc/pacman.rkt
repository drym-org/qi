#lang racket/base

(provide list→stream
         stream→list
         map
         filter
         foldl
         foldr
         take
         range
         car
         list-ref
         list-update
         indexes-where
         dup
         amp
         zip2
         zipl)

(require (prefix-in b: racket/base)
         (only-in racket/math sqr)
         data/gvector
         racket/performance-hint
         racket/unsafe/ops)

(begin-encourage-inline

  ;; consumers
  (define-inline (stream→list previous)
    (let* ([pre-head (cons '() '())]
           [tail pre-head])
      (previous (λ () (b:cdr pre-head))
                (λ (v return)
                  (let ([new-tail (cons v '())])
                    (unsafe-set-immutable-cdr! tail new-tail)
                    (set! tail new-tail)
                    (return))))))

  (define-inline (foldl op init previous)
    (let ([result init])
      (previous (λ ()
                  result)
                (λ (v return)
                  (set! result (op v result))
                  (return)))))

  (define-inline (foldr op init previous)
    (previous (λ ()
                init)
              (λ (v return)
                (op v (return)))))

  (define-inline (list-ref n previous)
    (let ([n n])
      (previous (λ () (error "Out of elements!"))
                (λ (v return)
                  (if (> n 0)
                      (begin (set! n (sub1 n))
                             (return))
                      v)))))

  (define-inline (car previous)
    (list-ref 0 previous))

  ;; transformers

  (define-inline (map f previous)
    (λ (done yield)
      (previous done
                (λ (v return)
                  (yield (f v)
                         return)))))

  (define-inline (filter f previous)
    (λ (done yield)
      (previous done
                (λ (v return)
                  (if (f v)
                      (yield v return)
                      (return))))))

  (define-inline (take n previous)
    (let ([remaining n])
      (λ (done yield)
        (previous done
                  (λ (v return)
                    (if (> remaining 0)
                        (begin
                          (set! remaining (sub1 remaining))
                          (yield v return))
                        (done)))))))

  (define-inline (list-update index updater previous)
    (let ([pos -1])
      (λ (done yield)
        (previous (λ ()
                    (if (< pos index)
                        (error "out of elements!")
                        (done)))
                  (λ (v return)
                    (begin (set! pos (add1 pos))
                           (yield (if (= index pos) (updater v) v)
                                  return)))))))

  (define-inline (indexes-where pred previous)
    (let ([pos -1])
      (λ (done yield)
        (previous done
                  (λ (v return)
                    (begin (set! pos (add1 pos))
                           (if (pred v)
                               (yield pos
                                      return)
                               (return))))))))

  (define-inline (append-map previous)
    (λ (done yield)
      (previous done
                (λ (v return)
                  (let go ([rem-vs v])
                    (if (null? rem-vs)
                        (return)
                        (let ([v (b:car rem-vs)]
                              [rem-vs (b:cdr rem-vs)])
                          (yield v
                                 (λ ()
                                   (go rem-vs))))))))))

  (define-inline (dup previous)
    (λ (done yield)
      (previous done
                (λ (v return)
                  (yield v
                         (λ ()
                           (yield v
                                  return)))))))

  (define-inline (one-two-three previous)
    (λ (done yield)
      (previous done
                (λ (v return)
                  (yield v
                         (λ ()
                           (yield (+ 1 v)
                                  (λ ()
                                    (yield (+ 2 v)
                                           return)))))))))

  (define-inline (amp f previous)
    (λ (done yield)
      (previous done
                (λ (v return)
                  (let ([fvs (call-with-values (λ () (f v))
                                               list)])
                    (let go ([fvs fvs])
                      (if (null? fvs)
                          (return)
                          (if (null? (b:cdr fvs))
                              (yield (b:car fvs)
                                     return)
                              (yield (b:car fvs)
                                     (λ ()
                                       (go (b:cdr fvs))))))))))))

  (define-inline (shift previous)
    (let ([buffer #false])
      (λ (done yield)
        (previous (λ ()
                    (yield buffer
                           done))
                  (λ (v return)
                    (if buffer
                        (let ([vb buffer])
                          (set! buffer v)
                          (yield vb
                                 return))
                        (begin
                          (set! buffer v)
                          (return))))))))


  (define-inline (pair previous)
    (let ([buffer #false])
      (λ (done yield)
        (previous (λ ()
                    (if buffer
                        (yield (list buffer)
                               done)
                        (done)))
                  (λ (v return)
                    (if buffer
                        (let ([buffered-v buffer])
                          (set! buffer #false)
                          (yield (list buffered-v v)
                                 return))
                        (begin
                          (set! buffer v)
                          (return))))))))

  (define-inline (before-first v-alt previous [splice? #false])
    (let ([state #false])
      (λ (done yield)
        (previous done
                  (λ (v return)
                    (if state
                        (yield v return)
                        (begin
                          (set! state #true)
                          (if splice?
                              (let go ([v-alts v-alt])
                                (if (null? v-alts)
                                    (yield v return)
                                    (let ([v-alt (b:car v-alts)]
                                          [v-alts (b:cdr v-alts)])
                                      (yield v-alt
                                             (λ ()
                                               (go v-alts))))))
                              (yield v-alt
                                     (λ ()
                                       (yield v return)))))))))))

  (define-inline (after-last v-alt previous [splice? #false])
    (λ (done yield)
      (previous (λ ()
                  (if splice?
                      (let go ([vs v-alt])
                        (if (null? vs)
                            (done)
                            (let ([v (b:car vs)]
                                  [vs (b:cdr vs)])
                              (yield v
                                     (λ ()
                                       (go vs))))))
                      (yield v-alt
                             done)))
                yield)))

  (define-inline (add-between v-alt previous [v-bl v-alt] [splice? #false])
    (let ([state #false])
      (λ (done yield)
        (previous (λ ()
                    (if state
                        (if (eq? 'first (b:car state))
                            (yield (b:cdr state)
                                   done)
                            (if splice?
                                (let go ([v-bls v-bl])
                                  (if (null? v-bls)
                                      (yield (b:cdr state)
                                             done)
                                      (let ([v-bl (b:car v-bls)]
                                            [v-bls (b:cdr v-bls)])
                                        (yield v-bl
                                               (λ ()
                                                 (go v-bls))))))
                                (yield v-bl
                                       (λ ()
                                         (yield (b:cdr state)
                                                done)))))
                        (done)))
                  (λ (v return)
                    (if state
                        (let ([kind (b:car state)]
                              [buffered-v (b:cdr state)])
                          (set! state (cons 'typical v))
                          (if (eq? 'first kind)
                              (yield buffered-v
                                     return)
                              (if splice?
                                  (let go ([v-alts v-alt])
                                    (if (null? v-alts)
                                        (yield buffered-v
                                               return)
                                        (let ([v-alt (b:car v-alts)]
                                              [v-alts (b:cdr v-alts)])
                                          (yield v-alt
                                                 (λ ()
                                                   (go v-alts))))))
                                  (yield v-alt
                                         (λ ()
                                           (yield buffered-v
                                                  return))))))
                        (begin (set! state (cons 'first v))
                               (return))))))))

  (define-inline (zipl op init . prevs-orig)
    (let ([returns (make-gvector)]
          [result init])
      (λ (done yield)
        (let go ([prevs prevs-orig]
                 [index 0])
          (if (null? prevs)
              (let ([final-result result])
                (set! result init)
                (yield final-result (λ () (go prevs-orig 0))))
              (let ([prev (b:car prevs)]
                    [prevs (b:cdr prevs)]
                    [return (gvector-ref returns index #false)])
                (if return
                    (return)
                    (prev done
                          (λ (v return)
                            (gvector-set! returns index return)
                            (set! result (op v result))
                            (go prevs (add1 index)))))))))))

  (define-inline (zip2 op left right)
    (let ([left-return #false]
          [right-return #false]
          [left-v #false])
      (λ (done yield)
        (if left-return
            (left-return)
            (left done
                  (λ (v return)
                    (set! left-return return)
                    (set! left-v v)
                    (if right-return
                        (right-return)
                        (right done
                               (λ (v return)
                                 (set! right-return return)
                                 (yield (op left-v v)
                                        left-return))))))))))

  (define-inline (interleave . prevs-orig)
    (λ (done yield)
      (let ([returns (make-gvector)]
            [buffer null])
        (let go ([prevs prevs-orig]
                 [index 0])
          (if (null? prevs)
              (let go-yield ([vs buffer])
                (if (null? vs)
                    (begin (set! buffer null)
                           (go prevs-orig 0))
                    (let ([v (b:car vs)]
                          [vs (b:cdr vs)])
                      (yield v
                             (λ ()
                               (go-yield vs))))))
              (let ([prev (b:car prevs)]
                    [prevs (b:cdr prevs)]
                    [return (gvector-ref returns index #false)])
                (if return
                    (return)
                    (prev done
                          (λ (v return)
                            (gvector-set! returns index return)
                            (set! buffer (cons v buffer))
                            (go prevs (add1 index)))))))))))

  (define-inline (unzip previous)
    (let ([left (λ (done yield)
                  (previous done
                            (λ (v return)
                              (yield (b:car v)
                                     return))))]
          [right (λ (done yield)
                   (previous done
                             (λ (v return)
                               (yield (b:cdr v)
                                      return))))])
      (values left right)))

  (define-inline (split f previous)
    (let ([left (λ (done yield)
                  (previous done
                            (λ (v return)
                              (if (f v)
                                  (yield v
                                         return)
                                  (return)))))]
          [right (λ (done yield)
                   (previous done
                             (λ (v return)
                               (if (f v)
                                   (return)
                                   (yield v
                                          return)))))])
      (values left right)))

  ;; producers
  (define-inline (list→stream vs)
    (λ (done yield)
      (let go ([vs vs])
        (if (null? vs)
            (done)
            (yield (b:car vs)
                   (λ ()
                     (go (b:cdr vs))))))))

  (define-inline (range low high step)
    (λ (done yield)
      (let go ([low low])
        (if (>= low high)
            (done)
            (yield low
                   (λ ()
                     (go (+ low step)))))))))

(module+ main
  (require rackunit
           rackunit/text-ui)

  (define tests
    (test-suite
     "pacman tests"

     (test-suite
      "stream"
      (check-equal? (stream→list (list→stream (list 1 2 3 4 5)))
                    (list 1 2 3 4 5)))

     (test-suite
      "range"
      (check-equal? (stream→list (range 0 10 2))
                    (list 0 2 4 6 8))
      (check-equal? (stream→list (range 1 10 2))
                    (list 1 3 5 7 9))
      (check-equal? (stream→list
                     (range 0 10 1))
                    (list 0 1 2 3 4 5 6 7 8 9)))

     (test-suite
      "zipl"
      (check-equal? (stream→list (zipl cons null (list→stream '(a b c d e)) (list→stream '(1 2 3 4 5))))
                    '((1 a) (2 b) (3 c) (4 d) (5 e)))
      (check-equal? (stream→list (zipl cons null (list→stream '(a b c)) (list→stream '(1 2 3 4 5))))
                    '((1 a) (2 b) (3 c)))
      (check-equal? (stream→list (zipl cons null (list→stream '(a b c d e)) (list→stream '(1 2 3))))
                    '((1 a) (2 b) (3 c)))
      (check-equal? (stream→list (zipl cons null (list→stream '(a b c d e)) (list→stream '(1 2 3 4 5)) (list→stream '(A B C D E))))
                    '((A 1 a) (B 2 b) (C 3 c) (D 4 d) (E 5 e))))

     (test-suite
      "zipr"
      (check-equal? (stream→list (map reverse (zipl cons null (list→stream '(a b c d e)) (list→stream '(1 2 3 4 5)))))
                    '((a 1) (b 2) (c 3) (d 4) (e 5)))
      (check-equal? (stream→list (map reverse (zipl cons null (list→stream '(a b c)) (list→stream '(1 2 3 4 5)))))
                    '((a 1) (b 2) (c 3)))
      (check-equal? (stream→list (map reverse (zipl cons null (list→stream '(a b c d e)) (list→stream '(1 2 3)))))
                    '((a 1) (b 2) (c 3)))
      (check-equal? (stream→list (map reverse (zipl cons null (list→stream '(a b c d e)) (list→stream '(1 2 3 4 5)) (list→stream '(A B C D E)))))
                    '((a 1 A) (b 2 B) (c 3 C) (d 4 D) (e 5 E))))

     (test-suite
      "interleave"
      (check-equal? (stream→list (interleave (list→stream '(1 2 3 4 5)) (list→stream '(a b c d e))))
                    '(a 1 b 2 c 3 d 4 e 5))
      (check-equal? (stream→list (interleave (list→stream '(1 2 3 4 5)) (list→stream '(a b c))))
                    '(a 1 b 2 c 3))
      (check-equal? (stream→list (interleave (list→stream '(1 2 3)) (list→stream '(a b c d e))))
                    '(a 1 b 2 c 3)))

     (test-suite
      "pair"
      (check-equal? (stream→list (pair (list→stream '(1 2 3 4 5))))
                    '((1 2) (3 4) (5))))

     (test-suite
      "add-between"
      (check-equal? (stream→list (add-between 0 (list→stream (list 1 2 3 4 5))))
                    (list 1 0 2 0 3 0 4 0 5))
      (check-equal? (stream→list (after-last 10 (before-first 10 (add-between 0 (list→stream (list 1 2 3 4 5)) -1))))
                    (list 10 1 0 2 0 3 0 4 -1 5 10))
      (check-equal? (stream→list (add-between (list 0 0) (list→stream (list 1 2 3 4 5)) (list -1 -1) #true))
                    (list 1 0 0 2 0 0 3 0 0 4 -1 -1 5)))

     (test-suite
      "before-first"
      (check-equal? (stream→list (before-first 0 (list→stream (list 1 2 3 4 5))))
                    (list 0 1 2 3 4 5))
      (check-equal? (stream→list (before-first (list 0 0 0) (list→stream (list 1 2 3 4 5)) #true))
                    (list 0 0 0 1 2 3 4 5)))

     (test-suite
      "after-last"
      (check-equal? (stream→list (after-last 10 (list→stream (list 1 2 3 4 5))))
                    '(1 2 3 4 5 10))
      (check-equal? (stream→list (after-last (list 10 10 10) (list→stream (list 1 2 3 4 5)) #true))
                    '(1 2 3 4 5 10 10 10)))

     (test-suite
      "map"
      (check-equal? (stream→list
                     (map sqr (list→stream '(1 2 3 4 5))))
                    '(1 4 9 16 25)))

     (test-suite
      "filter"
      (check-equal? (stream→list
                     (filter odd? (list→stream (list 1 2 3 4 5))))
                    '(1 3 5)))

     (test-suite
      "list-update"
      (check-equal? (stream→list
                     (list-update 2 (λ (v) 0) (list→stream (list 1 2 3 4 5))))
                    '(1 2 0 4 5)))

     (test-suite
      "indexes-where"
      (check-equal? (stream→list
                     (indexes-where odd? (list→stream (list 1 2 3 4 5))))
                    '(0 2 4)))

     (test-suite
      "append-map"
      (check-equal? (stream→list
                     (append-map (list→stream '((1) (2) (3) (4) (5)))))
                    '(1 2 3 4 5)))

     (test-suite
      "foldl"
      (check-equal? (foldl cons null (list→stream (list 1 2 3)))
                    '(3 2 1)))

     (test-suite
      "foldr"
      (check-equal? (foldr cons null (list→stream (list 1 2 3)))
                    '(1 2 3)))

     (test-suite
      "take"
      (check-equal? (stream→list
                     (take 2 (list→stream (list 1 2 3 4))))
                    '(1 2)))

     (test-suite
      "list-ref"
      (check-equal? (list-ref 2
                              (list→stream (list 1 2 3 4)))
                    3)
      ;; (check-false (list-ref 5
      ;;                        (list→stream (list 1 2 3))))
      )
     (test-suite
      "dup"
      (check-equal? (stream→list
                     (dup
                      (list→stream (list 1 2 3))))
                    '(1 1 2 2 3 3)))
     (test-suite
      "combinations"
      (check-equal? (stream→list (add-between 0 (dup (list→stream (list 1 2 3))) 10))
                    '(1 0 1 0 2 0 2 0 3 10 3))
      (check-equal? (foldl cons null (add-between 0 (dup (list→stream (list 1 2 3))) 10))
                    '(3 10 3 0 2 0 2 0 1 0 1))
      (check-equal? (foldr cons null (add-between 0 (dup (list→stream (list 1 2 3))) 10))
                    '(1 0 1 0 2 0 2 0 3 10 3))
      (check-equal? (foldr cons null (after-last -1 (before-first -1 (add-between 0 (dup (list→stream (list 1 2 3))) 10))))
                    '(-1 1 0 1 0 2 0 2 0 3 10 3 -1))
      (check-equal? (foldr cons null (shift (dup (list→stream (list 1 2 3)))))
                    '(1 1 2 2 3 3))
      (check-equal? (foldl cons null (one-two-three (list→stream (list 1 2 3))))
                    '(5 4 3 4 3 2 3 2 1))
      (check-equal? (foldr cons null (one-two-three (list→stream (list 1 2 3))))
                    '(1 2 3 2 3 4 3 4 5))
      (check-equal? (foldr cons null (after-last 0 (dup (list→stream (list 1 2 3)))))
                    '(1 1 2 2 3 3 0))
      (check-equal? (stream→list (dup (range 1 10 2)))
                    '(1 1 3 3 5 5 7 7 9 9))
      (check-equal? (stream→list
                     (map sqr
                          (filter odd?
                                  (list→stream (list 1 2 3 4 5)))))
                    '(1 9 25))
      (check-equal? (foldl + 0
                           (map sqr
                                (filter odd?
                                        (list→stream (list 1 2 3 4 5)))))
                    35)
      (check-equal? (list-ref 5
                              (range 0 100 2))
                    10)
      (check-equal? (list-ref 5
                              (filter odd? (range 0 100 1)))
                    11)
      (check-equal? (foldl + 0
                           (dup
                            (list→stream (list 1 2 3))))
                    12)
      (check-equal? (foldr + 0
                           (dup
                            (list→stream (list 1 2 3))))
                    12)
      (check-equal? (foldl + 0
                           (filter odd?
                                   (list→stream (list 1 2 3))))
                    4)
      (check-equal? (foldr + 0
                           (filter odd?
                                   (list→stream (list 1 2 3))))
                    4)
      (check-equal? (stream→list
                     (dup
                      (amp (λ (v) (values (sqr v) (sqr v)))
                           (dup (list→stream (list 1 2 3))))))
                    '(1 1 1 1 1 1 1 1 4 4 4 4 4 4 4 4 9 9 9 9 9 9 9 9))
      (check-equal? (stream→list
                     (amp (λ (v) (values))
                          (dup (list→stream (list 1 2 3)))))
                    '())
      (check-equal? (car
                     (range 0 100 2))
                    0)
      (check-equal? (stream→list
                     (dup
                      (range 0 3 1)))
                    '(0 0 1 1 2 2))
      (check-equal? (stream→list
                     (dup
                      (map sqr
                           (dup
                            (range 1 4 1)))))
                    '(1 1 1 1 4 4 4 4 9 9 9 9))
      (check-equal? (stream→list
                     (take 5
                           (filter odd? (range 0 100 1))))
                    '(1 3 5 7 9)))))

  (void (run-tests tests)))
