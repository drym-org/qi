#lang racket/base

(provide (all-defined-out))

(require (prefix-in b: racket/base)
         racket/unsafe/ops
         (prefix-in b: (only-in racket/list make-list))
         racket/performance-hint
         (only-in racket/math sqr))

(begin-encourage-inline

  ;; core runtime

  (define-inline (stream map
                         [init (void)]
                         [next void]
                         [stop? (case-λ [(_v _s) #false]
                                        [(_s) #true])]
                         [exit (case-λ [(_s) (values)]
                                       [(_v _s) (values)])])
    (λ (previous)
      (let ([state init])
        (λ (done yield)
          (previous (case-λ [()
                             (let go ([state state])
                               (if (stop? state)
                                   (call-with-values (λ () (exit state))
                                                     done)
                                   (call-with-values (λ () (map state))
                                                     (case-λ [() (go (next state))]
                                                             [(v) (yield v
                                                                         (λ ()
                                                                           (go (next state))))]
                                                             [vs (let go2 ([vs vs])
                                                                   (if (b:null? vs)
                                                                       (go (next state))
                                                                       (yield (b:car vs)
                                                                              (λ ()
                                                                                (go2 (b:cdr vs))))))]))))]
                            [(result) (error "Expected stream.")])
                    (λ (v return)
                      (if (stop? v state)
                          (call-with-values (λ () (exit v state))
                                            done)
                          (let ([original-state state])
                            (set! state (next v state))
                            (call-with-values (λ () (map v original-state))
                                              (case-λ [() (return)]
                                                      [(fv) (yield fv return)]
                                                      [fvs (let go ([fvs fvs])
                                                             (if (b:null? fvs)
                                                                 (return)
                                                                 (yield (b:car fvs)
                                                                        (λ ()
                                                                          (go (b:cdr fvs))))))]))))))))))

  ;; producers

  (define-inline (list→stream vs)
    ((stream b:car
             vs
             b:cdr
             b:null?)
     (λ (done _yield)
       (done))))

  (define-inline (range low high step)
    ((stream values
             low
             (λ (s) (+ s step))
             (λ (s) (>= s high)))
     (λ (done _yield)
       (done))))

  (define-inline (make-list k v)
    ((stream (λ (_s) v)
             k
             sub1
             zero?)
     (λ (done _yield)
       (done))))

  (define-inline (listlist→stream vs)
    ((stream (λ (s) (apply values (b:car s)))
             vs
             b:cdr
             b:null?)
     (λ (done _yield)
       (done))))

  ;; transformers

  (define-inline (map f previous)
    ((stream (λ (v _s) (f v)))
     previous))

  (define-inline (filter pred previous)
    ((stream (λ (v _s) (if (pred v) v (values))))
     previous))

  (define-inline (filter-not f previous)
    ((stream (λ (v _s) (if (f v) (values) v)))
     previous))

  (define-inline (filter-map f previous)
    ((stream (λ (v _s) (or (f v) (values))))
     previous))

  (define-inline (take n previous)
    ((stream (case-λ [(v _s) v]
                     [(_s) (error "out of elements")])
             0
             (λ (_v s) (add1 s))
             (case-λ [(_v s) (= n s)]
                     [(s) (= n s)]))
     previous))

  (define-inline (list-tail n previous)
    ((stream (case-λ [(v s) (if (>= s n) v (values))]
                     [(_s) (error "out of elements")])
             0
             (λ (_v s) (add1 s))
             (case-λ [(_v _s) #false]
                     [(s) (>= s n)]))
     previous))

  (define-inline (takef f previous)
    ((stream (λ (v _s) v)
             (void)
             void
             (case-λ [(v _s) (not (f v))]
                     [(_s) #true]))
     previous))

  (define-inline (remf pred previous)
    ((stream (λ (v s)
               (if (or s (not (pred v)))
                   v
                   (values)))
             #false
             (λ (v s)
               (or s (pred v))))
     previous))

  (define-inline (memf f previous)
    ((stream (λ (v s)
               (if (or s (f v))
                   v
                   (values)))
             #false
             (λ (v s) (or s (f v)))
             (case-λ [(_v _s) #false]
                     [(_s) #true])
             (λ (s) (if s (values) #false)))
     previous))

  (define-inline (dropf f previous)
    ((stream (λ (v s)
               (if (or s (not (f v)))
                   v
                   (values)))
             #false
             (λ (v s) (or s (not (f v)))))
     previous))

  (define-inline (list-update index updater previous)
    ((stream (case-λ [(v s) (if (= index s) (updater v) v)]
                     [(_s) (error "out of elements")])
             0
             (λ (_v s) (add1 s))
             (case-λ [(_v _s) #false]
                     [(s) (> s index)]))
     previous))

  (define-inline (indexes-where pred previous)
    ((stream (λ (v s) (if (pred v) s (values)))
             0
             (λ (_v s) (add1 s)))
     previous))

  (define-inline (dup n previous)
    ((stream (λ (v _s) (apply values (b:make-list n v))))
     previous))

  (define-inline (amp f previous)
    ((stream (λ (v _s) (f v)))
     previous))

  (define-inline (join previous)
    ((stream (λ (v _s) (apply values v)))
     previous))

  (define-inline (append-map f previous)
    (join (map f previous)))

  (define-inline (pair previous)
    ((stream (case-λ [(v s) (if s (list s v) (values))]
                     [(s) (list s)])
             #false
             (case-λ [(v s) (if s #false v)]
                     [(s) #false])
             (case-λ [(_v _s) #false]
                     [(s) (not s)]))
     previous))

  (define-inline (before-first v-alt previous)
    ((stream (case-λ [(v s)
                      (if (b:null? s)
                          v
                          (apply values (append v-alt (list v))))]
                     [(s) (b:car s)])
             v-alt
             (case-λ [(_v _s) '()]
                     [(s) (b:cdr s)])
             (case-λ [(_v _s) #false]
                     [(s) (b:null? s)]))
     previous))

  (define-inline (after-last v-alt previous)
    ((stream (case-λ [(v _s) v]
                     [(s) (b:car s)])
             v-alt
             (case-λ [(_v s) s]
                     [(s) (b:cdr s)])
             (case-λ [(_v _s) #false]
                     [(s) (b:null? s)]))
     previous))

  (define-inline (add-between v-alt before-last previous)
    ((stream (case-λ [(v s) (cond [(void? s) v]
                                  [s (apply values (append v-alt (list s)))]
                                  [else (values)])]
                     [(s) (if (void? s)
                              (values)
                              (apply values (append before-last (list s))))])
             (void)
             (case-λ [(v s) (if (void? s) #false v)]
                     [(_s) #false])
             (case-λ [(_v _s) #false]
                     [(s) (not s)]))
     previous))

  ;; consumers

  (define-inline (reverse previous)
    (((stream (λ (_v _s) (values))
              '()
              cons
              (case-λ [(_v _s) #false]
                      [(_s) #true])
              (λ (s) s))
      previous)
     values
     (λ (_v _s) (values))))

  (define-inline (stream→list-true previous)
    (((stream (λ (_v _s) (values))
              '()
              cons
              (case-λ [(_v _s) #false]
                      [(_s) #true])
              (λ (s) (b:reverse s)))
      previous)
     values
     (λ (_v _s) (values))))

  (define-inline (stream→list previous)
    (let* ([pre-head (cons '() '())]
           [tail pre-head])
      (previous (case-λ [() (b:cdr pre-head)]
                        [(result) result])
                (λ (v return)
                  (let ([new-tail (cons v '())])
                    (unsafe-set-immutable-cdr! tail new-tail)
                    (set! tail new-tail)
                    (return))))))

  (define-inline (foldl op init previous)
    (((stream (λ (_v _s) (values))
              init
              op
              (case-λ [(_v _s) #false]
                      [(_s) #true])
              (λ (s) s))
      previous)
     values
     (λ (_v _s) (values))))

  (define-inline (foldr op init previous)
    (previous (λ () init)
              (λ (v k-return)
                (op v (k-return)))))

  (define-inline (list-ref n previous)
    (((stream (case-λ [(_v _s) (values)]
                      [(_s) (error "out of values!")])
              0
              (λ (_v s) (add1 s))
              (case-λ [(_v s) (= n s)]
                      [(_s) #false])
              (λ (v _s) v))
      previous)
     values
     (λ (_v _s) (values))))

  (define-inline (car previous)
    (list-ref 0 previous))

  (define-inline (length previous)
    (((stream (λ (_v _s) (values))
              0
              (λ (_v s) (add1 s))
              (case-λ [(_v s) #false]
                      [(_s) #true])
              (λ (s) s))
      previous)
     values
     (λ (_v _s) (values))))

  (define-inline (empty? previous)
    (((stream (λ (_v _s) (values))
              #true
              (λ (_v _s) #false)
              (case-λ [(_v _s) #true]
                      [(_s) #true])
              (case-λ [(_v s) #false]
                      [(_s) #true]))
      previous)
     values
     (λ (_v _s) (values))))

  (define-inline (pair? previous)
    (((stream (λ (_v _s) (values))
              0
              (λ (_v s) (add1 s))
              (case-λ [(_v s) (> s 1)]
                      [(s) #true])
              (case-λ [(_v _s) #true]
                      [(s) (> s 1)]))
      previous)
     values
     (λ (_v _s) (values))))

  (define-inline (assf f previous)
    (((stream (λ (_v _s) (values))
              #false
              (λ (v _s)
                (if (b:pair? v)
                    (and (f (b:car v)) v)
                    (error (format "found non-pair: ~a" v))))
              (case-λ [(_v s) s]
                      [(_s) #true])
              (case-λ [(_v s) s]
                      [(s) s]))
      previous)
     values
     (λ (_v _s) (values))))

  (define-inline (index-where pred previous)
    (((stream (λ (_v _s) (values))
              0
              (λ (_v s) (add1 s))
              (case-λ [(v _s) (pred v)]
                      [(_s) #true])
              (case-λ [(_v s) s]
                      [(s) #false]))
      previous)
     values
     (λ (_v _s) (values))))

  (define-inline (index-of v-to-find = previous)
    (((stream (λ (_v _s) (values))
              0
              (λ (_v s) (add1 s))
              (case-λ [(v _s) (= v-to-find v)]
                      [(_s) #true])
              (case-λ [(_v s) s]
                      [(_s) #false]))
      previous)
     values
     (λ (_v _s) (values))))

  (define-inline (findf pred previous)
    (((stream (λ (_v _s) (values))
              (void)
              (λ (_v s) s)
              (case-λ [(v _s) (pred v)]
                      [(_s) #true])
              (case-λ [(v _s) v]
                      [(_s) #false]))
      previous)
     values
     (λ (_v _s) (values))))

  (define-inline (argcomp f compare previous)
    (((stream (λ (_v _s) (values))
              #false
              (λ (v s)
                (if s
                    (if (compare (f v) (f s))
                        v
                        s)
                    v))
              (case-λ [(v s) #false]
                      [(s) #true])
              (λ (s) (or s (error "out of values!"))))
      previous)
     values
     (λ (_v _s) (values)))))

(module+ main
  (require rackunit
           rackunit/text-ui)

  (define tests
    (test-suite
     "core streams tests"

     (test-suite
      "producers"

      (test-suite
       "list→stream"
       (check-equal? (stream→list (list→stream (list 1 2 3 4 5)))
                     (list 1 2 3 4 5)))

      (test-suite
       "range"
       (check-equal? (stream→list (range 0 10 2))
                     (list 0 2 4 6 8))
       (check-equal? (stream→list (range 1 10 2))
                     (list 1 3 5 7 9))
       (check-equal? (stream→list (range 0 10 1))
                     (list 0 1 2 3 4 5 6 7 8 9)))

      (test-suite
       "make-list"
       (check-equal? (stream→list (make-list 5 'a))
                     '(a a a a a))
       (check-equal? (stream→list (make-list 0 'a))
                     '()))

      (test-suite
       "listlist→stream"
       (check-equal? (stream→list (listlist→stream '((1) (2) (3) (4) (5))))
                     (list 1 2 3 4 5))
       (check-equal? (stream→list (listlist→stream '((1 2) (3 4) (5))))
                     (list 1 2 3 4 5))))

     (test-suite
      "transformers"

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
       "filter-not"
       (check-equal? (stream→list
                      (filter-not odd? (list→stream (list 1 2 3 4 5))))
                     '(2 4)))
      (test-suite
       "filter-map"
       (check-equal? (stream→list
                      (filter-map (λ (v) (and (negative? v) (abs v)))
                                  (list→stream '(1 2 -3 -4 8))))
                     '(3 4)))
      (test-suite
       "take"
       (check-equal? (stream→list
                      (take 2 (list→stream (list 1 2 3 4))))
                     '(1 2))
       (check-equal? (stream→list
                      (take 0 (list→stream (list 1 2 3 4))))
                     '())
       (check-exn exn:fail?
                  (λ ()
                    (stream→list
                     (take 5 (list→stream (list 1 2 3 4)))))))
      (test-suite
       "list-tail"
       (check-equal? (stream→list
                      (list-tail 2 (list→stream (list 1 2 3 4))))
                     '(3 4))
       (check-equal? (stream→list
                      (list-tail 0 (list→stream (list 1 2 3 4))))
                     '(1 2 3 4))
       (check-equal? (stream→list
                      (list-tail 4 (list→stream (list 1 2 3 4))))
                     '())
       (check-exn exn:fail?
                  (λ ()
                    (stream→list
                     (list-tail 5 (list→stream (list 1 2 3 4)))))))
      (test-suite
       "takef"
       (check-equal? (stream→list
                      (takef odd? (list→stream (list 1 3 4 5))))
                     '(1 3))
       (check-equal? (stream→list
                      (takef odd? (list→stream (list 1 3))))
                     '(1 3))
       (check-equal? (stream→list
                      (takef odd? (list→stream (list 4 5))))
                     '())
       (check-equal? (stream→list
                      (takef odd? (list→stream '())))
                     '()))

      (test-suite
       "remf"
       (check-equal? (stream→list (remf (λ (v) (eq? v 'c)) (list→stream '(a b c d c e))))
                     '(a b d c e))
       (check-equal? (stream→list (remf (λ (v) (equal? v (list 3))) (list→stream '((1) (2) (3) (4) (3) (5)))))
                     '((1) (2) (4) (3) (5)))
       (check-equal? (stream→list (remf (λ (v) (eq? v 'd)) (list→stream '(a b c))))
                     '(a b c)))

      (test-suite
       "memf"
       (check-equal? (stream→list
                      (memf odd? (list→stream (list 2 4 5 6))))
                     '(5 6))
       (check-false (stream→list
                     (memf odd? (list→stream (list 2 4 6))))))

      (test-suite
       "dropf"
       (check-equal? (stream→list
                      (dropf odd? (list→stream (list 1 3 4 5))))
                     '(4 5))
       (check-equal? (stream→list
                      (dropf odd? (list→stream (list 1 3))))
                     '())
       (check-equal? (stream→list
                      (dropf odd? (list→stream (list 4 5))))
                     '(4 5))
       (check-equal? (stream→list
                      (dropf odd? (list→stream '())))
                     '()))

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
       "dup"
       (check-equal? (stream→list
                      (dup 2
                           (list→stream (list 1 2 3))))
                     '(1 1 2 2 3 3)))

      (test-suite
       "amp"
       (check-equal? (stream→list
                      (amp sqr
                           (list→stream (list 1 2 3))))
                     '(1 4 9))
       (check-equal? (stream→list
                      (amp (λ (v) (values v v))
                           (list→stream (list 1 2 3))))
                     '(1 1 2 2 3 3)))

      (test-suite
       "join"
       (check-equal? (stream→list
                      (join (list→stream '((1) (2) (3) (4) (5)))))
                     '(1 2 3 4 5))
       (check-equal? (stream→list
                      (join (list→stream '(() ()))))
                     '()))

      (test-suite
       "append-map"
       (check-equal? (stream→list
                      (append-map values (list→stream '((1) (2) (3) (4) (5)))))
                     '(1 2 3 4 5))
       (check-equal? (stream→list
                      (append-map vector->list (list→stream '(#(1) #(2) #(3) #(4) #(5)))))
                     '(1 2 3 4 5))
       (check-equal? (stream→list
                      (append-map (λ (v) (list v v)) (list→stream '(1 2 3))))
                     '(1 1 2 2 3 3)))

      (test-suite
       "pair"
       (check-equal? (stream→list (pair (list→stream '(1 2 3 4 5))))
                     '((1 2) (3 4) (5))))

      (test-suite
       "before-first"
       (check-equal? (stream→list (before-first (list 0) (list→stream (list 1 2 3 4 5))))
                     (list 0 1 2 3 4 5))
       (check-equal? (stream→list (before-first (list 0 0 0) (list→stream (list 1 2 3 4 5))))
                     (list 0 0 0 1 2 3 4 5)))

      (test-suite
       "after-last"
       (check-equal? (stream→list (after-last (list 10) (list→stream (list 1 2 3 4 5))))
                     '(1 2 3 4 5 10))
       (check-equal? (stream→list (after-last (list 10 10 10) (list→stream (list 1 2 3 4 5))))
                     '(1 2 3 4 5 10 10 10)))

      (test-suite
       "add-between"
       (check-equal? (stream→list (add-between (list 0) (list 0) (list→stream (list 1 2 3 4 5))))
                     (list 1 0 2 0 3 0 4 0 5))
       (check-equal? (stream→list (after-last (list 10) (before-first (list 10) (add-between (list 0) (list -1) (list→stream (list 1 2 3 4 5))))))
                     (list 10 1 0 2 0 3 0 4 -1 5 10))
       (check-equal? (stream→list (add-between (list 0 0) (list -1 -1) (list→stream (list 1 2 3 4 5))))
                     (list 1 0 0 2 0 0 3 0 0 4 -1 -1 5))
       (check-equal? (stream→list (add-between (list 0) (list -1) (list→stream (list 1))))
                     (list 1))
       (check-equal? (stream→list (add-between (list 0) (list -1) (list→stream (list 1 2))))
                     (list 1 -1 2))))

     (test-suite
      "consumers"

      (test-suite
       "stream→list-true"
       (check-equal? (stream→list-true (list→stream (list 1 2 3)))
                     '(1 2 3)))

      (test-suite
       "reverse"
       (check-equal? (reverse (list→stream (list 1 2 3)))
                     (list 3 2 1))
       (check-equal? (reverse (list→stream '()))
                     '())
       (check-equal? (reverse (list→stream '(1)))
                     '(1)))

      (test-suite
       "foldl"
       (check-equal? (foldl cons null (list→stream (list 1 2 3)))
                     '(3 2 1)))

      (test-suite
       "foldr"
       (check-equal? (foldr cons null (list→stream (list 1 2 3)))
                     '(1 2 3)))

      (test-suite
       "list-ref"
       (check-equal? (list-ref 2
                               (list→stream (list 1 2 3 4)))
                     3)
       (check-exn exn:fail? (λ ()
                              (list-ref 5
                                        (list→stream (list 1 2 3))))))

      (test-suite
       "car"
       (check-equal? (car (list→stream (list 1 2 3 4)))
                     1)
       (check-exn exn:fail? (λ ()
                              (car (list→stream '())))))

      (test-suite
       "length"
       (check-equal? (length (list→stream (list 1 2 3 4)))
                     4)
       (check-equal? (length (list→stream '()))
                     0))

      (test-suite
       "empty?"
       (check-false (empty? (list→stream (list 1))))
       (check-true (empty? (list→stream '()))))

      (test-suite
       "pair?"
       (check-true (pair? (list→stream (list 1 2))))
       (check-false (pair? (list→stream '(1)))))

      (test-suite
       "assf"
       (check-false (assf (λ (v) (= v 7)) (list→stream '((1 2) (3 4) (5 6)))))
       (check-equal? (assf (λ (v) (= v 1)) (list→stream '((1 2) (3 4) (5 6))))
                     '(1 2))
       (check-equal? (assf (λ (v) (= v 3)) (list→stream '((1 2) (3 4) (5 6))))
                     '(3 4))
       (check-equal? (assf (λ (v) (= v 5)) (list→stream '((1 2) (3 4) (5 6))))
                     '(5 6)))

      (test-suite
       "index-of"
       (check-equal? (index-of 3 equal? (list→stream (list 1 2 3 4 5)))
                     2)
       (check-false (index-of 4 equal? (list→stream (list 1 2 3)))))

      (test-suite
       "index-where"
       (check-equal? (index-where (λ (v) (= v 3)) (list→stream (list 1 2 3 4 5)))
                     2)
       (check-false (index-where (λ (v) (= v 4)) (list→stream (list 1 2 3)))))

      (test-suite
       "findf"
       (check-equal? (findf odd? (list→stream (list 2 3 4 5)))
                     3)
       (check-false (findf odd? (list→stream (list 2 4)))))

      (test-suite
       "argcomp"
       (check-equal? (argcomp string-length < (list→stream (list "banana" "apple" "avocado")))
                     "apple")
       (check-exn exn:fail? (λ () (argcomp string-length < (list→stream '()))))))

     (test-suite
      "combinations"
      (check-exn exn:fail?
                 (λ ()
                   (stream→list
                    (map sqr (memf odd? (list→stream (list 2 4 6)))))))
      (check-equal? (stream→list (add-between (list 0) (list 10) (dup 2 (list→stream (list 1 2 3)))))
                    '(1 0 1 0 2 0 2 0 3 10 3))
      (check-equal? (foldl cons null (add-between (list 0) (list 10) (dup 2 (list→stream (list 1 2 3)))))
                    '(3 10 3 0 2 0 2 0 1 0 1))
      (check-equal? (foldr cons null (add-between (list 0) (list 10) (dup 2 (list→stream (list 1 2 3)))))
                    '(1 0 1 0 2 0 2 0 3 10 3))
      (check-equal? (foldr cons null (after-last (list -1) (before-first (list -1) (add-between (list 0) (list 10) (dup 2 (list→stream (list 1 2 3)))))))
                    '(-1 1 0 1 0 2 0 2 0 3 10 3 -1))
      (check-equal? (foldr cons null (after-last (list 0) (dup 2 (list→stream (list 1 2 3)))))
                    '(1 1 2 2 3 3 0))
      (check-equal? (stream→list (dup 2 (range 1 10 2)))
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
                           (dup 2
                                (list→stream (list 1 2 3))))
                    12)
      (check-equal? (foldr + 0
                           (dup 2
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
                     (dup 2
                          (amp (λ (v) (values (sqr v) (sqr v)))
                               (dup 2 (list→stream (list 1 2 3))))))
                    '(1 1 1 1 1 1 1 1 4 4 4 4 4 4 4 4 9 9 9 9 9 9 9 9))
      (check-equal? (stream→list
                     (amp (λ (v) (values))
                          (dup 2 (list→stream (list 1 2 3)))))
                    '())
      (check-equal? (car
                     (range 0 100 2))
                    0)
      (check-equal? (stream→list
                     (dup 2
                          (range 0 3 1)))
                    '(0 0 1 1 2 2))
      (check-equal? (stream→list
                     (dup 2
                          (map sqr
                               (dup 2
                                    (range 1 4 1)))))
                    '(1 1 1 1 4 4 4 4 9 9 9 9))
      (check-equal? (stream→list
                     (take 5
                           (filter odd? (range 0 100 1))))
                    '(1 3 5 7 9)))))

  (void (run-tests tests)))
