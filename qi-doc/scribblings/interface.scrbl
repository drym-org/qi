#lang scribble/doc
@require[scribble/manual
         scribble-abbrevs/manual
         scribble/example
         racket/sandbox
         @for-label[qi
                    racket
                    (only-in relation
                             ->number
                             ->string
                             sum)]]

@(define eval-for-docs
  (parameterize ([sandbox-output 'string]
                 [sandbox-error-output 'string]
                 [sandbox-memory-limit #f])
    (make-evaluator 'racket/base
                    '(require qi
                              (only-in racket/list range)
                              racket/string
                              relation)
                    '(define (sqr x)
                       (* x x)))))

@title{Language Interface}

The core entry-point to the flow language is the form @racket[☯]. In addition, other forms such as @racket[on], @racket[switch], and @racket[~>] build on top of @racket[☯] to provide convenient syntax in specialized cases. Together, these forms represent the interface between the host language (e.g. Racket) and Qi.

@table-of-contents[]

@section{Core}

@deftogether[(
@defform*/subs[[(☯ flow-expr)]
               ([flow-expr _
                           (gen expr ...)
                           △
                           sep
                           ▽
                           collect
                           (esc expr)
                           (clos flow-expr)
                           (one-of? expr ...)
                           (all flow-expr)
                           (any flow-expr)
                           (none flow-expr)
                           (and flow-expr ...)
                           (or flow-expr ...)
                           (not flow-expr)
                           (and% flow-expr ...)
                           (or% flow-expr ...)
                           NOT
                           !
                           AND
                           &
                           OR
                           ∥
                           NOR
                           NAND
                           XOR
                           XNOR
                           any?
                           all?
                           none?
                           inverter
                           ⏚
                           ground
                           (~> flow-expr ...)
                           (thread flow-expr ...)
                           (~>> flow-expr ...)
                           (thread-right flow-expr ...)
                           X
                           crossover
                           (== flow-expr ...)
                           (relay flow-expr ...)
                           (-< flow-expr ...)
                           (tee flow-expr ...)
                           (fanout number)
                           (feedback number flow-expr)
                           count
                           1>
                           2>
                           3>
                           4>
                           5>
                           6>
                           7>
                           8>
                           9>
                           (select index ...)
                           (block index ...)
                           (bundle (index ...) flow-expr flow-expr)
                           (group number flow-expr flow-expr)
                           (sieve flow-expr flow-expr flow-expr)
                           (if flow-expr flow-expr flow-expr)
                           (when flow-expr flow-expr)
                           (unless flow-expr flow-expr)
                           (switch switch-expr ...)
                           (gate flow-expr)
                           (>< flow-expr)
                           (amp flow-expr)
                           (pass flow-expr)
                           (<< flow-expr expr)
                           (>> flow-expr expr)
                           (loop flow-expr flow-expr flow-expr flow-expr)
                           (loop2 flow-expr flow-expr flow-expr)
                           (ε flow-expr flow-expr)
                           (effect flow-expr flow-expr)
                           apply
                           literal
                           (quote value)
                           (quasiquote value)
                           (quote-syntax value)
                           (syntax value)
                           (expr expr ... __ expr ...)
                           (expr expr ... _ expr ...)
                           (expr expr ...)
                           expr]
                [expr a-racket-expression]
                [index exact-positive-integer?]
                [number exact-nonnegative-integer?]
                [switch-expr [flow-expr flow-expr]
                             [flow-expr (=> flow-expr)]
                             [else flow-expr]]
                [literal a-racket-literal]
                [value a-racket-value])]
  @defform[(flow flow-expr)]
  )]{
  Define a @tech{flow} by using the various @seclink["Qi_Forms"]{forms} of the Qi language.

This produces a value that is an ordinary function. When invoked with arguments, this function passes those arguments as inputs to the defined flow, producing its outputs as return values. A flow defined in this manner does not name its inputs, and like any function, it only produces output when it is invoked with inputs.

See also @racket[on] and @racket[~>], which are shorthands to invoke the flow with arguments immediately.

@examples[
    #:eval eval-for-docs
    ((☯ (* 5)) 3)
    ((☯ (and positive? odd?)) 5)
    ((☯ (~> + (* 2))) 3 5)
  ]
}

@defform[(on (arg ...) flow-expr)]{
  Define and execute a @tech{flow} with the inputs named in advance.

  This is a way to pass inputs to a flow that is an alternative to the usual function invocation syntax (i.e. an alternative to simply invoking the flow with arguments). It may be preferable in certain cases, since the inputs are named at the beginning rather than at the end.

  In the respect that it both defines as well as invokes the flow, it has the same relationship to @racket[☯] as @racket[let] has to @racket[lambda], and can be used in analogous ways.

  Equivalent to @racket[((☯ flow-expr) arg ...)].

@examples[
    #:eval eval-for-docs
    (on (5) (and positive? odd?))
    (on ((* 2 3) (+ 5 2))
      (~> (>< ->string)
          string-append))
  ]
}

@section{Threading}

@deftogether[(
@defform[(~> (args ...) flow-expr ...)]
@defform[(~>> (args ...) flow-expr ...)]
)]{
  These @emph{Racket} forms leverage the identically-named @emph{Qi} forms to thread inputs through a sequence of flows. @racket[~>] threads arguments in the first position by default, while @racket[~>>] uses the last position, but in either case the positions can instead be explicitly indicated by using @racket[_] or @racket[__].

  @margin-note{In these docs, we'll sometimes refer to the host language as "Racket" for convenience, but it should be understood that Qi may be used with any host language.}

  As flows themselves can be nonlinear, these threading forms too support arbitrary arity changes along the way to generating the result.

  In the respect that these both define as well as invoke the flow, they have the same relationship to @racket[☯] as @racket[let] has to @racket[lambda], and can be used in analogous ways.

  Equivalent to @racket[((☯ (~> flow-expr ...)) args ...)].

  See also: @secref["Relationship_to_the_Threading_Macro"].

@examples[
    #:eval eval-for-docs
	(~> (3) sqr add1)
	(~> (3) (-< sqr add1) +)
	(~> ("a" "b") (string-append "c"))
	(~>> ("b" "c") (string-append "a"))
	(~> ("a" "b") (string-append _ "-" _))
  ]
}

@section[#:tag "interface-conditionals"]{Conditionals}

@defform[(switch (arg ...)
           maybe-divert-clause
           [predicate consequent]
           ...
           [else consequent])]{
  A predicate-based dispatch form, usable as an alternative to @racket[cond], @racket[if], and @racket[match].

Each of the @racket[predicate] and @racket[consequent] expressions is a flow, and they are each typically invoked with @racket[arg ...], so that the arguments need not be mentioned anywhere in the body of the form.

 This @emph{Racket} form leverages the identically-named @emph{Qi} form. See @secref["Conditionals"] for its full syntax and behavior.

@examples[
    #:eval eval-for-docs
	(switch (5)
	  [(and positive? odd?) (~> sqr add1)]
	  [else _])
	(switch (2 3)
	  [< +]
	  [else min])
  ]
}

@section{Lambdas}

  These anonymous function forms may be used in cases where you need to explicitly @emph{name} the arguments for some reason. Otherwise, in most cases, just use @racket[☯] directly instead as it produces a function while avoiding the extraneous layer of bindings.

@deftogether[(
  @defform[(flow-lambda args body ...)]
  @defform[(π args body ...)]
)]{
  Similiar to @racket[lambda] but constrained to the flow language. This is exactly equivalent to @racket[(lambda args (on (args) body ...))]. @racket[π] is an alias for @racket[flow-lambda]. The present form mainly finds its use internally in @racket[define-flow], and in most cases you should use @racket[☯] directly.
}

@deftogether[(
@defform[(switch-lambda (args ...)
           [predicate consequent ...]
           ...
           [else consequent ...])]
@defform[(λ01 (args ...)
           [predicate consequent ...]
           ...
           [else consequent ...])]
)]{
  Similar to @racket[lambda] but constrained to be a flow-based dispatcher. This is exactly equivalent to @racket[(lambda args (switch (args) [predicate consequent ...] ... [else consequent ...]))]. @racket[λ01] is an alias for @racket[switch-lambda].

@examples[
    #:eval eval-for-docs
	((switch-lambda (x)
	   [(and positive? odd?) (~> sqr add1)]
	   [else _]) 5)
  ]
}

@section{Definitions}

The following definition forms may be used in place of the usual general-purpose @racket[define] form when defining flows.

@deftogether[(
  @defform[(define-flow (name args) body ...)]
)]{
  Similiar to the function form of @racket[define] but constrained to the flow language. This is exactly equivalent to @racket[(define name (lambda/subject args body ...))].
}

@defform[(define-switch (args ...)
           [predicate consequent ...]
           ...
           [else consequent ...])]{
  Similiar to the function form of @racket[define] but constrained to be a (predicate-based) dispatcher. This is exactly equivalent to @racket[(define name (switch-lambda args [predicate consequent ...] ... [else consequent ...]))].

@examples[
    #:eval eval-for-docs
    (define-switch abs
      [negative? -]
      [else _])
    (map abs (list -1 2 -3 4 -5))
  ]
}

The advantage of using these over the general-purpose @racket[define] form is that, as they express the definition at the appropriate level of abstraction and with the attendant constraints for the type of flow, they can be more clear and more robust, minimizing boilerplate while providing guardrails against programmer error.

@section{Interoperating with the Host Language}

Arbitrary native (e.g. Racket) expressions can be used in flows in one of two ways. The first and most common way is to simply wrap the expression with a @racket[gen] form while within a flow context. This flow generates the @tech/reference{value} of the expression.

The second way is if you want to describe a flow using the native language instead of the flow language. In this case, use the @racket[esc] form. The wrapped expression in this case @emph{must} evaluate to a function, since functions are the only values describable in the native language that can be treated as flows. Note that use of @racket[esc] is unnecessary for function identifiers since these are usable as flows directly, and these can even be partially applied using standard application syntax, optionally with @racket[_] and @racket[__] to indicate argument placement. But you may still need it in the specific case where the identifier collides with a Qi form.
