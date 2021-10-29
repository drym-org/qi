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
                              relation)
                    '(define (sqr x)
                       (* x x)))))

@title{Qi: A Functional, Flow-Oriented DSL}
@author{Siddhartha Kasivajhula}

@defmodule[qi]

An embeddable, general-purpose, Turing-complete language to allow convenient framing of programming logic in terms of functional @emph{flows}.

One way to structure computations -- the one we typically employ when writing functions in Racket or another programming language -- is as a flowchart, with arrows representing logical transitions indicating the sequence in which actions are performed. In this model, aside from the implied ordering, the actions are independent of one another and could be anything at all. Another way -- provided by the present module -- is where computations are structured as a flow like a flow of energy, electricity passing through a circuit, streams flowing around rocks. In this model, arrows represent that the outputs of one flow feed into another.

The former way is often necessary when writing functions at a low level, where the devil is in the details. But once these functional building blocks are available, the latter model is often more appropriate, allowing us to compose functions at a high level to derive complex and robust functional pipelines from simple components with a minimum of repetition and boilerplate, engendering @hyperlink["https://www.theschooloflife.com/thebookoflife/wu-wei-doing-nothing/"]{effortless clarity}. The facilities in the present module allow you to employ this flow-oriented model in any source program.

@examples[
    #:eval eval-for-docs
    ((☯ (~> sqr add1)) 3)
    ((☯ (and positive? odd?)) 5)
    ((☯ (<= 5 _ 10)) 6)
    ((☯ (<= 5 _ 10)) 12)
    ((☯ (~> (>< ->string) string-append)) 5 7)
    (~> (2 3) + sqr)
    (define-switch (abs n)
      [negative? -]
      [else _])
    (abs -5)
    (abs 5)
    (define-flow (≈ m n)
      (~> - abs (< 1)))
    (≈ 5 7)
    (≈ 5 5.4)
    (define-flow (root-mean-square vs)
      (~>> (map sqr) (-< sum length) / sqrt))
    (root-mean-square (range 10))
  ]

@section{Introduction}

 A @deftech{flow} is either made up of flows, or is a native (e.g. Racket) function. Flows may be composed using a number of combinators that could yield either linear or nonlinear composite flows.

 The flow @racket[gen] allows an ordinary value to be "lifted" into a flow -- thus, any value can be incorporated into flows.

 The semantics of a flow is function invocation -- simply invoke a flow with inputs (i.e. ordinary arguments) to obtain the outputs. A flow in general is @code{n × m}, i.e. it accepts @code{n} inputs and yields @code{m} outputs, for arbitrary non-negative integers @code{m} and @code{n}.

@section{Syntax}

This section provides a specification of the basic syntax recognizable to all of the forms provided in this module.

@;{TODO: describe syntax - and, or, %, not, apply, with-key, .., and%, or%, ...}

@section{Interface}

The core interface to the flow language is the form @racket[☯]. In addition, other forms such as @racket[on], @racket[switch], and @racket[~>] build on top of @racket[☯] to provide convenient syntax in specialized cases. @racket[on] provides a way to declare the arguments to the flow up front. @racket[~>] is similar to @racket[on] but implicitly threads the arguments through a sequence of flows. @racket[switch] is a conditional dispatch form analogous to @racket[cond] whose predicate and consequent expressions are all flows. In addition, other forms like @racket[define-flow] and @racket[define-switch] are provided that leverage these to create functions constrained to the flow language, for use in defining predicates, dispatchers, or arbitrary transformations. The advantage of using these forms over the usual general-purpose @racket[define] form is that they are more clear and more robust, as the constraints they impose minimize boilerplate by narrowing scope, while also providing guardrails against programmer error.

@deftogether[(
@defform*/subs[[(☯ flow-expr)]
               ([flow-expr _
                           (one-of? expr ...)
                           (all flow-expr)
                           (any flow-expr)
                           (none flow-expr)
                           (and flow-expr ...)
                           (or flow-expr ...)
                           (not flow-expr)
                           (gen expr ...)
                           NOT
                           !
                           AND
                           &
                           OR
                           ||
                           NOR
                           NAND
                           XOR
                           XNOR
                           (and% flow-expr ...)
                           (or% flow-expr ...)
                           any?
                           all?
                           none?
                           ▽
                           collect
                           △
                           sep
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
                           (select index ...)
                           (block index ...)
                           (bundle (index ...) flow-expr flow-expr)
                           (group number flow-expr flow-expr)
                           (sieve flow-expr flow-expr flow-expr)
                           (if flow-expr flow-expr flow-expr)
                           (switch switch-expr ...)
                           (gate flow-expr)
                           1>
                           2>
                           3>
                           4>
                           5>
                           6>
                           7>
                           8>
                           9>
                           (fanout number)
                           (feedback flow-expr number)
                           inverter
                           (ε flow-expr flow-expr)
                           (effect flow-expr flow-expr)
                           (>< flow-expr)
                           (amp flow-expr)
                           (pass flow-expr)
                           (<< flow-expr expr)
                           (>> flow-expr expr)
                           (loop flow-expr flow-expr flow-expr flow-expr)
                           (loop2 flow-expr flow-expr flow-expr)
                           apply
                           (esc flow-expr ...)
                           literal
                           (quote value)
                           (quasiquote value)
                           (quote-syntax value)
                           (syntax value)
                           (expr expr ... __ expr ...)
                           (expr expr ... _ expr ...)
                           (expr expr ...)
                           expr
                           _]
                [expr a-racket-expression]
                [index exact-positive-integer?]
                [number exact-nonnegative-integer?]
                [literal a-racket-literal]
                [value a-racket-value])]
  @defform[(flow flow-expr)]
  )]{
  Define a @tech{flow}.

@examples[
    #:eval eval-for-docs
	((☯ (and positive? odd?)) 5)
  ]
}

@defform[(on (args ...) flow-expr)]{
  Define a @tech{flow} with the inputs named in advance.

  Typically, @racket[on] should only be used for the general case of evaluating an expression in the context of a pre-defined subject (such as while defining a predicate). For the more specific case of predicate-based dispatch, use @racket[switch].
@examples[
    #:eval eval-for-docs
	(on (5) (and positive? odd?))
  ]
}

@deftogether[(
@defform[(~> (args ...) flow-expr ...)]
@defform[(~>> (args ...) flow-expr ...)]
)]{
  Thread inputs through a sequence of flows. @racket[~>] threads arguments in the first position by default, while @racket[~>>] uses the last position, but in either case the positions can instead be explicitly indicated by using @racket[_].

  As flows themselves can be nonlinear, these threading forms too support arbitrary arity changes along the way to generating the result.

@examples[
    #:eval eval-for-docs
	(~> (3) sqr add1)
	(~> (3) (-< sqr add1) +)
	(~> ("a" "b") (string-append "c"))
	(~>> ("b" "c") (string-append "a"))
	(~> ("a" "b") (string-append _ "-" _))
  ]
}

@defform[(switch (args ...)
           [predicate consequent ...]
           ...
           [else consequent ...])]{
  A predicate-based dispatch form, usable as an alternative to @racket[cond] and @racket[if].

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

@deftogether[(
  @defform[(flow-lambda args body ...)]
  @defform[(π args body ...)]
)]{
  Similiar to @racket[lambda] but constrained to the flow language. This is exactly equivalent to @racket[(lambda args (on (args) body ...))]. @racket[π] is an alias for @racket[flow-lambda].
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
  Similar to @racket[lambda] but constrained to be a (predicate-based) dispatcher. This is exactly equivalent to @racket[(lambda args (switch (args) [predicate consequent ...] ... [else consequent ...]))]. @racket[λ01] is an alias for @racket[switch-lambda].

@examples[
    #:eval eval-for-docs
	((switch-lambda (x)
	   [(and positive? odd?) (~> sqr add1)]
	   [else _]) 5)
  ]
}

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
}

@section{Forms}

@defidform[_]{
  The symbol @racket[_] means different things depending on the context, but when used on its own, it is the identity flow or trivial transformation, where the outputs are the same as the inputs.
}

@defform[(gen expr ...)]{
  Generate the values of the provided Racket expressions as flows. This is one of the most common ways to translate an ordinary value into a flow.
}

@defform[(one-of? expr ...)]{
  Is the input one of the indicated values?
}

@defform[(all flo)]{
  Do @emph{all} of the inputs satisfy the predicate @racket[flo]?
}

@defform[(any flo)]{
  Do @emph{any} of the inputs satisfy the predicate @racket[flo]?
}

@defform[(none flo)]{
  Output true if @emph{none} of the inputs satisfy the predicate @racket[flo].
}

@defform[(and flo ...)]{
  Output true if the inputs, when considered together, satisfy each of the @racket[flo] predicates.
}

@defform[(or flo ...)]{
  Output true if the inputs, when considered together, satisfy any of the @racket[flo] predicates.
}

@defform[(not flo)]{
  Output true if the inputs, when considered together, do @emph{not} satisfy the predicate @racket[flo].
}

@deftogether[(
@defform[#:link-target? #f
         (~> flo ...)]
@defform[#:link-target? #f
         (~>> flo ...)]
)]{
  Compose flows in sequence, from left to right. In the metaphor of an analog electrical circuit, you could think of this as a wire.

  @racket[~>] "threads" the arguments in the leading position, while @racket[~>>] threads them in the trailing position. Argument positions may also be explicitly indicated via a template¹, either individually or en masse.
}

@deftogether[(
@defform[(-< flo ...)]
@defform[(tee flo ...)]
)]{
  Tee junction.
}

@section{Usage}

The Qi language isn't specific to a domain (except the domain of functions!) and may be used in normal (e.g. Racket) code simply by employing the appropriate @seclink["Forms"]{form}.

Arbitrary native (e.g. Racket) expressions can be used in flows in one of two ways. The first and most common way is to simply wrap the expression with a @racket[gen] form while within a flow context. This flow generates the @tech/reference{value} of the expression. The second way is if you want to describe a flow using the native language instead of the flow language. In this case, use the @racket[esc] form. The wrapped expression in this case @emph{must} evaluate to a function, since functions are the only values describable in the native language that can be treated as flows. Note that use of @racket[esc] is unnecessary for function identifiers since these are usable as flows directly, and these can even be partially applied using standard application syntax, optionally with @racket[_] and @racket[__] to indicate argument placement. But you may still need it in the specific case where the identifier collides with a Qi form.
