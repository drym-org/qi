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

@title{Qi Forms}

The core syntax of the Qi language. These forms may be used in any flow.

@table-of-contents[]

@section{Basic}

@defidform[_]{
  The symbol @racket[_] means different things depending on the context, but when used on its own, it is the identity flow or trivial transformation, where the outputs are the same as the inputs.

@examples[
    #:eval eval-for-docs
    ((☯ _) 3)
    ((☯ _) 1 2)
    ((☯ (-< _ _)) 3)
  ]
}

@defform[(gen expr ...)]{
  Generate the values of the provided Racket expressions as flows. This is the most common way to translate an ordinary value into a flow.

@examples[
    #:eval eval-for-docs
    ((☯ (gen 1)) 3)
    ((☯ (gen (string-append "hello" " " "there")))
     3 4 5)
    ((☯ (gen 1 2)) 3)
  ]
}

@deftogether[(
  @defidform[△]
  @defidform[sep]
  @defform[#:link-target? #f
           (△ flo)]
  @defform[#:link-target? #f
           (sep flo)]
)]{
  Separate the input list into its component values. This is the inverse of @racket[▽].

  When used in parametrized form with a presupplied @racket[flo], this flow accepts any number of inputs, where the first is expected to be the list to be unraveled. In this form, the flow separates the list into its component values and passes each through @racket[flo] along with the remaining input values.

  @racket[△] and @racket[▽] often allow you to use functions directly where you might otherwise need to use an indirection like @racket[apply] or @racket[list].

@examples[
    #:eval eval-for-docs
    ((☯ (~> △ +)) (list 1 2 3 4))
    ((☯ (~> △ (>< sqr) ▽)) (list 1 2 3 4))
    ((☯ (~> (△ +) ▽)) (list 1 2 3) 10)
    (struct kitten (name age) #:transparent)
    ((☯ (~> (△ kitten) ▽))
     (list "Ferdinand" "Imp" "Zacky") 0)
  ]
}

@deftogether[(
  @defidform[▽]
  @defidform[collect]
)]{
  Collect the input values into a list. This is the inverse of @racket[△].

  @racket[△] and @racket[▽] often allow you to use functions directly where you might otherwise need to use an indirection like @racket[apply] or @racket[list].

@examples[
    #:eval eval-for-docs
    ((☯ (~> ▽ (string-join ""))) "a" "b" "c")
    ((☯ (~> △ (>< sqr) ▽)) (list 1 2 3 4))
  ]
}

@defform[(esc expr)]{
  Escape to the host language to evaluate @racket[expr] which is expected to yield a @tech{flow}.

@examples[
    #:eval eval-for-docs
    ((☯ (esc (λ (x) (+ 2 x)))) 3)
  ]
}

@section{Predicates}

@defform[(one-of? expr ...)]{
  Is the input one of the indicated values?

@examples[
    #:eval eval-for-docs
    ((☯ (one-of? 'a 'b 'c)) 'b)
  ]
}

@defform[(all flo)]{
  Do @emph{all} of the inputs satisfy the predicate @racket[flo]?

@examples[
    #:eval eval-for-docs
    ((☯ (all positive?)) 1 2 3)
    ((☯ (all positive?)) 1 -2 3)
  ]
}

@defform[(any flo)]{
  Do @emph{any} of the inputs satisfy the predicate @racket[flo]?

@examples[
    #:eval eval-for-docs
    ((☯ (any positive?)) -1 2 -3)
    ((☯ (any positive?)) -1 -2 -3)
  ]
}

@defform[(none flo)]{
  Output true if @emph{none} of the inputs satisfy the predicate @racket[flo].

@examples[
    #:eval eval-for-docs
    ((☯ (none positive?)) -1 2 -3)
    ((☯ (none positive?)) -1 -2 -3)
  ]
}

@defform[(and flo ...)]{
  Output true if the inputs, when considered together, satisfy each of the @racket[flo] predicates.

@examples[
    #:eval eval-for-docs
    ((☯ (and positive? odd?)) 9)
    ((☯ (and (all odd?) <)) 3 7 11)
  ]
}

@defform[(or flo ...)]{
  Output true if the inputs, when considered together, satisfy any of the @racket[flo] predicates.

@examples[
    #:eval eval-for-docs
    ((☯ (or positive? odd?)) 8)
    ((☯ (or (all odd?) <)) 3 8 12)
  ]
}

@defform[(not flo)]{
  Output true if the inputs, when considered together, do @emph{not} satisfy the predicate @racket[flo].

@examples[
    #:eval eval-for-docs
    ((☯ (not positive?)) -9)
    ((☯ (not <)) 8 3 12)
  ]
}

@defform[(and% flo ...)]{
  Output true if the inputs, when considered independently or "in parallel," satisfy each of the respective @racket[flo] predicates. Equivalent to @racket[(~> (== flo ...) AND)], except that the identifier @racket[_] when used in the present form indicates that you "don't care" about the corresponding input in determining the result (whereas it ordinarily indicates the identity transformation).

@examples[
    #:eval eval-for-docs
    ((☯ (and% positive? negative?)) 3 -9)
    ((☯ (and% positive? negative?)) -3 -9)
  ]
}

@defform[(or% flo ...)]{
  Output true if @emph{any} of the inputs, when considered independently or "in parallel," satisfies its corresponding @racket[flo] predicate. Equivalent to @racket[(~> (== flo ...) OR)], except that the identifier @racket[_] when used in the present form indicates that you "don't care" about the corresponding input in determining the result (whereas it ordinarily indicates the identity transformation).

@examples[
    #:eval eval-for-docs
    ((☯ (or% positive? negative?)) -3 -9)
    ((☯ (or% positive? negative?)) -3 9)
  ]
}

@section{Boolean Algebra}

@deftogether[(
  @defidform[NOT]
  @defidform[!]
)]{
  A Boolean NOT gate, this negates the input.

@examples[
    #:eval eval-for-docs
    ((☯ NOT) #t)
    ((☯ NOT) #f)
  ]
}

@deftogether[(
  @defidform[AND]
  @defidform[&]
)]{
  A Boolean AND gate, this outputs the conjunction of the inputs.

@examples[
    #:eval eval-for-docs
    ((☯ AND) #t #t #t)
    ((☯ AND) #t #f #t)
  ]
}

@deftogether[(
  @defidform[OR]
  @defidform[||]
)]{
  A Boolean OR gate, this outputs the disjunction of the inputs.

@examples[
    #:eval eval-for-docs
    ((☯ OR) #t #f #t)
    ((☯ OR) #f #f #f)
  ]
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

@examples[
    #:eval eval-for-docs
    ((☯ any?) #t #f #t)
    ((☯ any?) #f #f #f)
    ((☯ all?) #t #t #t)
    ((☯ all?) #t #f #t)
    ((☯ none?) #f #t #f)
    ((☯ none?) #f #f #f)
  ]
}

@defidform[inverter]{
  Negate each input in parallel. Equivalent to @racket[(>< NOT)].

@examples[
    #:eval eval-for-docs
    ((☯ inverter) #f #t #f)
  ]
}

@section{Routing}

@deftogether[(
  @defidform[⏚]
  @defidform[ground]
)]{
  Extinguish the input values, yielding no output at all.

@examples[
    #:eval eval-for-docs
    ((☯ ⏚) 1 2 3)
  ]
}

@deftogether[(
@defform[#:link-target? #f
         (~> flo ...)]
@defform[#:link-target? #f
         (~>> flo ...)]
)]{
  Compose flows in sequence, from left to right. In the metaphor of an analog electrical circuit, you could think of this as a wire.

  @racket[~>] "threads" the arguments in the leading position, while @racket[~>>] threads them in the trailing position. Argument positions may also be explicitly indicated via a @seclink["Templates_and_Partial_Application"]{template}, either individually or en masse.

@examples[
    #:eval eval-for-docs
    ((☯ (~> + sqr)) 1 2 3)
    ((☯ (~>> (string-append "a" "b"))) "c" "d")
  ]
}

@deftogether[(
@defidform[X]
@defidform[crossover]
)]{
  Invert the order of the inputs, so that the last output is the first input, the second-to-last output is the second input, and so on.

@examples[
    #:eval eval-for-docs
    ((☯ X) 1 2 3)
    ((☯ (~> X string-append)) "a" "b" "c")
  ]
}

@deftogether[(
@defform[(== flo ...)]
@defform[(relay flo ...)]
)]{
  Compose flows in parallel, so that inputs are passed through the corresponding @racket[flo]'s individually. The number of @racket[flo]s must be the same as the number of runtime inputs. As flows are nonlinear, the number of outputs will not necessarily be the same as the number of inputs.

@examples[
    #:eval eval-for-docs
    ((☯ (== add1 sub1)) 1 2)
  ]
}

@deftogether[(
@defform[(-< flo ...)]
@defform[(tee flo ...)]
)]{
  A "tee" junction, this forks the input values into multiple copies, each set of which is passed through a @racket[flo] "in parallel." Equivalent to @racket[(☯ (~> (fanout N) (== flo ...)))], where @racket[N] is the number of @racket[flo]'s.

@examples[
    #:eval eval-for-docs
    ((☯ (-< add1 sub1)) 3)
    ((☯ (-< + *)) 3 5)
  ]
}

@defform[(fanout N)]{
  Split the inputs into @racket[N] copies of themselves.

@examples[
    #:eval eval-for-docs
    ((☯ (fanout 3)) 5)
    ((☯ (fanout 2)) 3 7)
  ]
}

@defform[(feedback N flo)]{
  Pass the inputs @racket[N] times through @racket[flo] by "feeding back" the outputs each time.

@examples[
    #:eval eval-for-docs
    ((☯ (feedback 3 add1)) 5)
  ]
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
  Aliases for inputs, by index. Equivalent to @racket[(select N)], for index @racket[N]. If you need to select more than one input, use @racket[select] directly.

@examples[
    #:eval eval-for-docs
    ((☯ 4>) 'a 'b 'c 'd 'e 'f)
  ]
}

@deftogether[(
@defform[(select index ...)]
@defform[(block index ...)]
)]{
  Select or block inputs by index, outputting the selection or remainder, respectively. @racket[index] is @emph{1-indexed}, that is, for instance, in order to select the first and the third input, we would use @racket[(select 1 3)].

@examples[
    #:eval eval-for-docs
    ((☯ (select 1 4)) 'a 'b 'c 'd 'e 'f)
    ((☯ (block 1 2 4 6)) 'a 'b 'c 'd 'e 'f)
  ]
}

@defform[(bundle (index ...) selection-flo remainder-flo)]{
  Divide the set of inputs into two groups or "bundles" based on provided @emph{indexes}, passing the selection to @racket[selection-flo] and the remainder to @racket[remainder-flo].

@examples[
    #:eval eval-for-docs
    ((☯ (bundle (1 3) + *)) 1 2 3 4 5)
  ]
}

@defform[(group number selection-flo remainder-flo)]{
  Divide the set of inputs into two groups @emph{by number}, passing the first @racket[number] inputs to @racket[selection-flo] and the remainder to @racket[remainder-flo].

  In the context of a @racket[loop], this is a typical way to do "structural recursion" on flows, and in this respect it is the values analogue to @racket[car] and @racket[cdr] for lists.

@examples[
    #:eval eval-for-docs
    ((☯ (group 2 + *)) 1 2 3 4 5)
  ]
}

@defform[(sieve condition-flo selection-flo remainder-flo)]{
  Divide the set of inputs into two groups @emph{by condition}, passing the inputs that satisfy @racket[condition-flo] (individually) to @racket[selection-flo] and the remainder to @racket[remainder-flo].

@examples[
    #:eval eval-for-docs
    ((☯ (sieve positive? max min)) 1 -2 3 -4 5)
  ]
}

@section{Conditionals}

@deftogether[(
  @defform[(if condition-flo consequent-flo alternative-flo)]
  @defform[(when condition-flo consequent-flo)]
  @defform[(unless condition-flo alternative-flo)]
)]{
  The flow analogue of @racket[if], this is the basic conditional, passing the inputs through either @racket[consequent-flo] or @racket[alternative-flo], depending on whether they satisfy @racket[condition-flo].

  @racket[when] is shorthand for @racket[(if condition-flo consequent-flo ⏚)] and @racket[unless] is shorthand for @racket[(if condition-flo ⏚ alternative-flo)].

@examples[
    #:eval eval-for-docs
    ((☯ (if positive? add1 sub1)) 3)
    ((☯ (when positive? add1)) 3)
    ((☯ (unless positive? add1)) 3)
  ]
}

@defform*/subs[#:link-target? #f
               [(switch maybe-divert-expr switch-expr ...)]
                ([maybe-divert-expr (divert condition-gate-flow consequent-gate-flow)
                                    (% condition-gate-flow consequent-gate-flow)]
                 [switch-expr [flow-expr flow-expr]
                              [flow-expr (=> flow-expr)]
                              [else flow-expr]])]{
  The flow analogue of @racket[cond], this is a dispatcher where the condition and consequent expressions are all flows which operate on the switch inputs.

  Typically, each of the component flows -- conditions and consequents both -- receives all of the original inputs to the @racket[switch]. This can be changed by using a @racket[divert] clause, which takes two flow arguments, the first of whose outputs go to all of the condition flows, and the second of whose outputs go to all of the consequent flows. This can be useful in cases where multiple values flow, but only some of them are predicated upon, and others (or all of them) inform the actions to be taken. Using @racket[(divert _ _)] is equivalent to not using it. @racket[%] is a symbolic alias for @racket[divert] -- parse it visually not as the percentage sign, but as a convenient way to depict a "floodgate" diverting values down different channels.

  When the @racket[=>] form is used in a consequent flow, the consequent receives @emph{N + 1} inputs, where the first input is the result of the predicate flow, and the remaining @racket[N] inputs are the a priori inputs to the consequent flow (which are typically the original inputs to the switch, unless modulated with a @racket[divert] clause). This form is analogous to the @racket[=>] symbol when used in a @racket[cond]. Note that while switch can direct any number of values, we can unambiguously channel the result of the predicate to the first input of the consequent here because it is guaranteed to be a single value (otherwise it wouldn't be a predicate).

  If none of the conditions are met, this flow outputs @emph{no values}. If you need a specific value such as @racket[(void)], indicate it explicitly via @racket[[else void]].

@examples[
    #:eval eval-for-docs
    ((☯ (switch [positive? add1]
                [else sub1]))
     3)
    ((☯ (switch [(member (list 1 2 3)) (=> 1> (map - _))]
                [else 'not-found]))
     2)
    ((☯ (switch (% 1> _)
          [number? cons]
          [list? append]
          [else 2>]))
     (list 3)
     (list 1 2))
  ]
}

@defform[(gate condition-flo)]{
  Allow the inputs through unchanged if they satisfy @racket[condition-flo], otherwise, @racket[ground] them so that there is no output.

@examples[
    #:eval eval-for-docs
    ((☯ (gate <)) 3 5)
    ((☯ (gate <)) 5 1)
  ]
}

@section{Higher-order Flows}

@deftogether[(
@defform[(>< flo)]
@defform[(amp flo)]
)]{
  The flow analogue to @racket[map], this maps each input individually under @racket[flo]. As flows may generate any number of output values, unlike @racket[map], the number of outputs need not equal the number of inputs here, but will be some multiple.

@examples[
    #:eval eval-for-docs
    ((☯ (>< sqr)) 1 2 3)
    ((☯ (>< (-< _ _))) 1 2 3)
  ]
}

@defform[(pass condition-flo)]{
  The flow analogue to @racket[filter], this filters the input values individually under @racket[condition-flo], yielding only those values that satisfy it.

@examples[
    #:eval eval-for-docs
    ((☯ (pass positive?)) 1 -2 3)
  ]
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

@examples[
    #:eval eval-for-docs
    ((☯ (<< +)) 1 2 3 4)
    ((☯ (<< string-append)) "a" "b" "c" "d")
    ((☯ (>> string-append)) "a" "b" "c" "d")
    ((☯ (<< string-append "☯")) "a" "b" "c" "d")
  ]
}

@deftogether[(
  @defform[(loop condition-flo map-flo combine-flo return-flo)]
  @defform[#:link-target? #f
           (loop condition-flo map-flo combine-flo)]
  @defform[#:link-target? #f
           (loop condition-flo map-flo)]
  @defform[#:link-target? #f
           (loop map-flo)]
)]{
  A simple loop for structural recursion on the input values, this applies @racket[map-flo] to the first input on each successive iteration and recurses on the remaining inputs, combining these using @racket[combine-flo] to yield the result as long as the inputs satisfy @racket[condition-flo]. When the inputs do not satisfy @racket[condition-flo], @racket[return-flo] is applied to the inputs to yield the result at that terminating step. If the condition is satisfied and there are no further values, the loop terminates naturally.

  If unspecified, @racket[condition-flo] defaults to @racket[#t], @racket[combine-flo] defaults to @racket[_], and @racket[return-flo] defaults to @racket[⏚].

@examples[
    #:eval eval-for-docs
    ((☯ (loop (* 2))) 1 2 3)
    ((☯ (loop #t _ +)) 1 2 3 4)
  ]
}

@defform[(loop2 condition-flo map-flo combine-flo)]{
  A "tail-recursive" looping form, this passes the result at each step as a flow input to the next, alongside the inputs to the subsequent step, simply evaluating to the result flow on the last step.

@examples[
    #:eval eval-for-docs
    ((☯ (loop2 (~> 1> (not null?))
               sqr
               cons))
     (list 1 2 3) null)
  ]
}

@deftogether[(
  @defform[(ε side-effect-flo flo)]
  @defform[#:link-target? #f (ε side-effect-flo)]
  @defform[(effect side-effect-flo flo)]
  @defform[#:link-target? #f (effect side-effect-flo)]
)]{
  Pass the inputs through @racket[flo] but also independently to @racket[side-effect-flo]. The results of the latter, if any, are grounded, so they would have no effect on downstream flows, which would only receive the results of @racket[flo]. Equivalent to @racket[(-< (~> side-effect-flo ⏚) flo)].

  Use @racket[(ε side-effect-flo)] to just perform a side effect without modifying the input, equivalent to @racket[(-< (~> side-effect-flo ⏚) _)].

@examples[
    #:eval eval-for-docs
    ((☯ (~> (ε displayln sqr) add1)) 3)
  ]
}

@defidform[apply]{
  Analogous to @racket[apply], this treats the first input as a flow and passes the remaining inputs through it, producing the output that the input flow would produce if the argument flows were passed through it directly.

@examples[
    #:eval eval-for-docs
    ((☯ apply) + 1 2 3)
  ]
}

@section{Literals}

Literals and quoted values (including syntax-quoted values) in a flow context are interpreted as flows generating them. That is, for instance, @racket[5] in a flow context is equivalent to @racket[(gen 5)].

@examples[
    #:eval eval-for-docs
    ((☯ "hello") 1 2 3)
  ]

@section{Templates and Partial Application}

A parenthesized expression that isn't one of the Qi forms is treated as @emph{partial function application}, where the syntactically-indicated arguments are pre-supplied to yield a partially applied function that is applied to the input values at runtime.

Usually, the @racket[_] symbol indicates the trivial or identity flow, simply passing the inputs through unchanged. Within a partial application, however, the underscore indicates argument positions. If the expression includes a double underscore, @racket[__], then it is treated as a simple template such that the runtime arguments (however many there may be) are passed at the position indicated by the placeholder. Another type of template is indicated by using one or more single underscores. In this case, a specific number of runtime arguments are expected (corresponding to the number of blanks indicated by underscores). This more fine-grained template is powered under the hood by @other-doc['(lib "fancy-app/main.scrbl")].

@bold{N.B.}: In the examples below, and elsewhere in these docs, for some reason the double underscore renders in such a way that it is indistinguishable from a single underscore. You will have to infer from context which one is being used, that is, if more than one argument is being passed to a position, it must be a double underscore!

@examples[
    #:eval eval-for-docs
    ((☯ (* 3)) 7)
    ((☯ (string-append "c")) "a" "b")
    ((☯ (string-append "a" _ "c")) "b")
    ((☯ (< 5 _ 10)) 7)
    ((☯ (< 5 _ 7 _ 10)) 6 9)
    ((☯ (< 5 _ 7 _ 10)) 6 11)
    ((☯ (< 5 __ 10)) 6 7 8)
    ((☯ (< 5 __ 10)) 6 7 11)
  ]

@section{Utilities}

@defidform[count]{
  The arity of the flow. Analogous to @racket[length] for lists, this counts the values in the flow.

@examples[
    #:eval eval-for-docs
    ((☯ count) 5)
    ((☯ (~> (-< _ _ _) count)) 5)
  ]
}
