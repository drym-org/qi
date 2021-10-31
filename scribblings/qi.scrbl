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

One way to structure computations -- the one we typically employ when writing functions in Racket or another programming language -- is as a flowchart, with arrows representing logical transitions indicating the sequence in which actions are performed. In this model, aside from the implied ordering, the actions are independent of one another and could be anything at all. Another way -- provided by the present module -- is to structure computations as a flow like a flow of energy, electricity passing through a circuit, streams flowing around rocks. In this model, arrows represent that the outputs of one flow feed into another.

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

@section{Interface}

The core interface to the flow language is the form @racket[☯]. In addition, other forms such as @racket[on], @racket[switch], and @racket[~>] build on top of @racket[☯] to provide convenient syntax in specialized cases. @racket[on] provides a way to declare the arguments to the flow up front. @racket[~>] is similar to @racket[on] but implicitly threads the arguments through a sequence of flows. @racket[switch] is a conditional dispatch form analogous to @racket[cond] whose predicate and consequent expressions are all flows. In addition, other forms like @racket[define-flow] and @racket[define-switch] are provided that leverage these to create functions constrained to the flow language, for use in defining predicates, dispatchers, or arbitrary transformations. The advantage of using these forms over the usual general-purpose @racket[define] form is that, as they express the definition at the appropriate level of abstraction and with the right constraints, they can be more clear and more robust, often minimizing boilerplate while providing guardrails against programmer error.

@deftogether[(
@defform*/subs[[(☯ flow-expr)]
               ([flow-expr _
                           (gen expr ...)
                           △
                           sep
                           ▽
                           collect
                           (esc flow-expr ...)
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
                           ||
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
                           (feedback flow-expr number)
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
  These @emph{Racket} forms leverage the identically-named @emph{Qi} forms to thread inputs through a sequence of flows. @racket[~>] threads arguments in the first position by default, while @racket[~>>] uses the last position, but in either case the positions can instead be explicitly indicated by using @racket[_] or @racket[__].

  As flows themselves can be nonlinear, these threading forms too support arbitrary arity changes along the way to generating the result.

  Equivalent to @racket[((☯ (~> flow-expr ...)) args ...)].

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

@subsection{Basic}

@defidform[_]{
  The symbol @racket[_] means different things depending on the context, but when used on its own, it is the identity flow or trivial transformation, where the outputs are the same as the inputs.
}

@defform[(gen expr ...)]{
  Generate the values of the provided Racket expressions as flows. This is one of the most common ways to translate an ordinary value into a flow.
}

@deftogether[(
  @defidform[△]
  @defidform[sep]
)]{
  Separate the input list into its component values. This is the inverse of @racket[▽].

  @racket[△] and @racket[▽] often allow you to use functions directly where you might otherwise need to use an indirection like @racket[apply] or @racket[list].
}

@deftogether[(
  @defidform[▽]
  @defidform[collect]
)]{
  Collect the input values into a list. This is the inverse of @racket[△].

  @racket[△] and @racket[▽] often allow you to use functions directly where you might otherwise need to use an indirection like @racket[apply] or @racket[list].
}

@defform[(esc expr)]{
  Escapes to the host language to evaluate @racket[expr] which is expected to yield a @tech{flow}.
}

@subsection{Predicates}

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

@defform[(and% flo ...)]{
  Output true if the inputs, when considered independently or "in parallel," satisfy each of the respective @racket[flo] predicates. Equivalent to @racket[(~> (== flo ...) AND)], except that the identifier @racket[_] indicates that you "don't care" about the corresponding input in determining the result.
}

@defform[(or% flo ...)]{
  Output true if @emph{any} of the inputs, when considered independently or "in parallel," satisfies its corresponding @racket[flo] predicate. Equivalent to @racket[(~> (== flo ...) OR)], except that the identifier @racket[_] indicates that you "don't care" about the corresponding input in determining the result.
}

@subsection{Boolean Algebra}

@deftogether[(
  @defidform[NOT]
  @defidform[!]
)]{
  A Boolean NOT gate, this negates the input.
}

@deftogether[(
  @defidform[AND]
  @defidform[&]
)]{
  A Boolean AND gate, this outputs the conjunction of the inputs.
}

@deftogether[(
  @defidform[OR]
  @defidform[||]
)]{
  A Boolean OR gate, this outputs the disjunction of the inputs.
}

@deftogether[(
  @defidform[NOR]
  @defidform[NAND]
  @defidform[XOR]
  @defidform[XNOR]
)]{
  Flows corresponding to the identically-named Boolean gates.
}

@deftogether[(
  @defidform[any?]
  @defidform[all?]
  @defidform[none?]
)]{
  Output true if any, all, or none (respectively) of the inputs are truthy.
}

@defidform[inverter]{
  Negate each input in parallel. Equivalent to @racket[(>< NOT)].
}

@subsection{Routing}

@deftogether[(
  @defidform[⏚]
  @defidform[ground]
)]{
  Extinguish the input values, yielding no output at all.
}

@deftogether[(
@defform[#:link-target? #f
         (~> flo ...)]
@defform[#:link-target? #f
         (~>> flo ...)]
)]{
  Compose flows in sequence, from left to right. In the metaphor of an analog electrical circuit, you could think of this as a wire.

  @racket[~>] "threads" the arguments in the leading position, while @racket[~>>] threads them in the trailing position. Argument positions may also be explicitly indicated via a @seclink["Templates_and_Partial_Application"]{template}, either individually or en masse.
}

@deftogether[(
@defidform[X]
@defidform[crossover]
)]{
  Invert the order of the inputs, so that the last output is the first input, the second-to-last output is the second input, and so on.
}

@deftogether[(
@defform[(== flo ...)]
@defform[(relay flo ...)]
)]{
  Compose flows in parallel, so that inputs are passed through the corresponding @racket[flo]'s individually. The number of @racket[flo]s must be the same as the number of runtime inputs. As flows are nonlinear, the number of outputs will not necessarily be the same as the number of inputs.
}

@deftogether[(
@defform[(-< flo ...)]
@defform[(tee flo ...)]
)]{
  A "tee" junction, this forks the input values into multiple copies, each set of which is passed through a @racket[flo] "in parallel." Equivalent to @racket[(☯ (~> (fanout N) (== flo ...)))], where @racket[N] is the number of @racket[flo]'s.
}

@defform[(fanout N)]{
  Split the inputs into @racket[N] copies of themselves.
}

@defform[(feedback flo N)]{
  Pass the inputs @racket[N] times through @racket[flo] by "feeding back" the outputs each time.
}

@deftogether[(
  @defidform[1>]
  @defidform[2>]
  @defidform[3>]
  @defidform[4>]
  @defidform[5>]
  @defidform[6>]
  @defidform[7>]
  @defidform[8>]
  @defidform[9>]
)]{
  Aliases for inputs, by index. Equivalent to @racket[(select N)], for index @racket[N].
}

@deftogether[(
@defform[(select index ...)]
@defform[(block index ...)]
)]{
  Select or block inputs by index, outputting the selection or remainder, respectively. @racket[index] is @emph{1-indexed}, that is, for instance, in order to select the first and the third input, we would use @racket[(select 1 3)].
}

@defform[(bundle (index ...) selection-flo remainder-flo)]{
  Divide the set of inputs into two groups or "bundles" based on provided @emph{indexes}, passing the selection to @racket[selection-flo] and the remainder to @racket[remainder-flo].
}

@defform[(group number selection-flo remainder-flo)]{
  Divide the set of inputs into two groups @emph{by number}, passing the first @racket[number] inputs to @racket[selection-flo] and the remainder to @racket[remainder-flo].

  In the context of a @racket[loop], this is a typical way to do "structural recursion" on flows, and in this respect it is the values analogue to @racket[car] and @racket[cdr] for lists.
}

@defform[(sieve condition-flo selection-flo remainder-flo)]{
  Divide the set of inputs into two groups @emph{by condition}, passing the inputs that satisfy @racket[condition-flo] (individually) to @racket[selection-flo] and the remainder to @racket[remainder-flo].
}

@subsection{Conditionals}

@defform[(if condition-flo consequent-flo alternative-flo)]{
  The flow analogue of @racket[if], this is the basic conditional, passing the inputs through either @racket[consequent-flo] or @racket[alternative-flo], depending on whether they satisfy @racket[condition-flo].
}

@defform*/subs[#:link-target? #f
               [(switch switch-expr ...)]
            	([switch-expr [flow-expr flow-expr]
                              [flow-expr (=> flow-expr)]
                              [else flow-expr]])]{
  The flow analogue of @racket[cond], this is a predicate-based dispatcher where the predicate and consequent expressions are all flows. When the @racket[=>] form is used in a consequent flow, the consequent receives @emph{N + 1} inputs, where the first input is the result of the predicate flow, and the remaining @racket[N] inputs are the inputs to the switch. This form is analogous to the @racket[=>] symbol when used in a @racket[cond].
}

@defform[(gate condition-flo)]{
  Allows the inputs through unchanged if they satisfy @racket[condition-flo], otherwise, @racket[ground] them so that there is no output.
}

@subsection{Higher-order Flows}

@deftogether[(
@defform[(>< flo)]
@defform[(amp flo)]
)]{
  The flow analogue to @racket[map], this maps each input independently under @racket[flo], yielding the same number of outputs as inputs.
}

@defform[(pass condition-flo)]{
  The flow analogue to @racket[filter], this filters the input values under @racket[condition-flo], yielding only those values that satisfy it.
}

@deftogether[(
@defform[(<< flo init-flo)]
@defform[#:link-target? #f
         (<< flo)]
@defform[(>> flo init-flo)]
@defform[#:link-target? #f
         (>> flo)]
)]{
  The flow analogues to @racket[foldr] and @racket[foldl] (respectively -- the side on which the symbols "fold" corresponds to the type of fold), these fold over input values rather than an input list. The @racket[init-flo] is optional; if it isn't provided, @racket[flo] itself is invoked with no arguments to obtain the init value, to borrow a convention from the Clojure language.
}

@deftogether[(
  @defform[(loop condition-flo map-flo combine-flo return-flo)]
  @defform[#:link-target? #f
           (loop condition-flo map-flo combine-flo)]
  @defform[#:link-target? #f
           (loop condition-flo map-flo)]
)]{
  A simple loop for structural recursion on the input values, this applies @racket[map-flo] to the first input on each successive iteration and recurses on the remaining inputs, combining these using @racket[combine-flo] to yield the result as long as the inputs satisfy @racket[condition-flo]. When the inputs do not satisfy @racket[condition-flo], @racket[return-flo] is applied to the inputs to yield the result at that terminating step. If the condition is satisfied and there are no further values, the loop terminates naturally.
}

@defform[(loop2 condition-flo map-flo combine-flo)]{
  A "tail-recursive" looping form, this passes the result at each step as a flow input to the next, alongside the inputs to the subsequent step, simply evaluating to the result flow on the last step.
}

@deftogether[(
  @defform[(ε side-effect-flo flo)]
  @defform[(effect side-effect-flo flo)]
)]{
  Pass the inputs through @racket[flo] but also independently to @racket[side-effect-flo]. The results of the latter, if any, are grounded, so they would have no effect on downstream flows, which would only receive the results of @racket[flo]. Equivalent to @racket[(-< (~> side-effect-flo ⏚) flo)].
}

@defidform[apply]{
  Analogous to @racket[apply], this treats the first input as a flow and passes the remaining inputs through it, producing the output that the input flow would produce if the argument flows were passed through it directly.
}

@subsection{Literals}

Literals and quoted values (including syntax-quoted values) in a flow context are interpreted as flows generating them. That is, for instance, @racket[5] in a flow context is equivalent to @racket[(gen 5)].

@subsection{Templates and Partial Application}

A parenthesized expression that isn't one of the Qi forms is treated as a partial function application, i.e. with the syntactically-indicated arguments pre-supplied to yield a partially applied function that is applied to the input values at runtime. If such an expression includes a double underscore, @racket[__], then it is treated as a simple template such that the runtime arguments (however many there may be) are passed at the position indicated by the placeholder. Another type of template is a parenthesized expression including one or more single underscores. Such an expression is once again treated as partial application, but a specific number of runtime arguments are expected (corresponding to the number of blanks indicated by underscores). This more fine-grained template is powered under the hood by @other-doc['(lib "fancy-app/main.scrbl")].

@section{Usage}

The Qi language isn't specific to a domain (except the domain of functions!) and may be used in normal (e.g. Racket) code simply by employing the appropriate @seclink["Forms"]{form}.

Arbitrary native (e.g. Racket) expressions can be used in flows in one of two ways. The first and most common way is to simply wrap the expression with a @racket[gen] form while within a flow context. This flow generates the @tech/reference{value} of the expression. The second way is if you want to describe a flow using the native language instead of the flow language. In this case, use the @racket[esc] form. The wrapped expression in this case @emph{must} evaluate to a function, since functions are the only values describable in the native language that can be treated as flows. Note that use of @racket[esc] is unnecessary for function identifiers since these are usable as flows directly, and these can even be partially applied using standard application syntax, optionally with @racket[_] and @racket[__] to indicate argument placement. But you may still need it in the specific case where the identifier collides with a Qi form.
