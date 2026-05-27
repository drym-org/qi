#lang scribble/base

@require[(only-in scribble/jfp abstract)
         scribble/manual
         scriblib/figure]

@title{Language Extension Through Inheritance and Composition}

@centered{@bold{@tt{Technical Specification}}}
@centered{@bold{@tt{Status: @elem[#:style "status-archived"]{@tt{ARCHIVED}}}}}

@abstract{We look at a few different ways of extending a hosted language implemented in Syntax Spec. We describe a means of extension that affords the same flexibility to hosted languages that Syntax Spec already brings to the host language, that is, holistic and sound syntactic and runtime extensibility.}

@section{Background}

We want the Qi compiler to implement optimizations in terms of invariants distinct from the host language. We'd also like such optimizations to be extensible to arbitrary datatypes without bundling such optimizations in the core library, and would like to be able to use such optimizations in concert. Implementing a general solution in Syntax Spec could address these issues for all hosted languages.

@section{Proposal}

@subsection{Introduce a @code{language} type}

This type distinguishes expansion, compilation, and code generation as the distinct components of a language, providing a basis for a composable interface.

@codeblock{
  (struct language (base
                    expander
                    compiler
                    codegen))
}

We can ignore the @racket[base] attribute for the moment -- we'll discuss it later when we talk about inheritance.

@subsection{Defining languages}

To illustrate by example, we define three languages, @racket[qi-base], containing the core Qi language, @racket[qi-list] containing the list-specific forms (e.g. @racket[map] and @racket[filter]), and @racket[qi-std] containing the values-specific forms (e.g. @racket[><] and @racket[-<]).

@subsubsection{@racket[qi-base]}

@codeblock{
  (module qi-base
    (require "expander.rkt"
             "compiler.rkt"
             "codegen.rkt")

    (syntax-spec
      (language qi-base
        #:description "Qi base language"
        floe-base
        compile-floe-base
        qi-base->racket)

      (host-interface/language
        (flow f:floe-base))))
}

@subsubsection{@racket[qi-list]}

@codeblock{
  (module qi-list
    (require "expander.rkt"
             "compiler.rkt"
             qi/base)

    (syntax-spec
      (language qi-list
        #:description "Qi list language"
        #:base qi-base
        floe-list
        compile-floe-list)

      (host-interface/language
        (flow f:floe-list))))
}

@subsubsection{@racket[qi-std]}

@codeblock{
  (module qi-std
    (require "expander.rkt"
             "compiler.rkt"
             qi/base)

    (syntax-spec
      (language qi-std
        #:description "Qi standard language"
        #:base qi-base
        floe-std
        compile-floe-std)

      (host-interface/language
        (flow f:floe-std))))
}

Each of these languages declares its own expansion, compilation (including optimizations) and code generation. In the case of @racket[qi-base], the definition provides explicit implementations for all of these, while the other two languages indicate code generation implicitly by use of the @racket[#:base] argument. We will refer to this code block and discuss @racket[#:base] more soon, when we talk about inheritance. Other aspects like the expanders, via nonterminal (e.g. @racket[floe-list]) specifications, are defined in ways that are already supported in Syntax Spec as of this writing.

@subsection{Composing languages}

We compose the Qi language from these languages and provide it to the user in a way that matches the existing interface.

@codeblock{
  (module qi
    (provide (for-space qi (all-defined-out))
             flow)
    (require qi/base qi/list qi/std)

    (syntax-spec

      (language qi
        #:description "Qi language"
        #:compose (qi-list
                   qi-std)
        #:base qi-base
        #:as floe)

      (host-interface/language
        (flow f:floe))))
}

At the same time, we also provide @racket[qi-list], @racket[qi-std] and @racket[qi-base] directly, so that the user could compose it differently using the same Syntax Spec interface.

@codeblock{
  (module qi-minimal
    (provide (for-space qi (all-defined-out))
             flow)
    (require qi/base qi/std)

    (syntax-spec
      (language qi-minimal
        #:description "Qi minimal language"
        #:compose (qi-std)
        #:base qi-base
        #:as floe)

      (host-interface/language
        (flow f:floe))))

  (module my-application
    (require "qi-minimal.rkt"))
}

In this case, leaving out @racket[qi-list] if they aren't using lists in their application. As there is only one language in the composition here, @racket[qi-minimal] is equivalent to @racket[qi-std]. We expect @racket[(require qi)] to already be fairly minimal, so the flexibility to compose languages becomes more useful with an increasing number of community optimizations for bespoke data types, so that one might do:

@codeblock{
  (module qi-datascience
    (provide (for-space qi (all-defined-out)))
    (require qi/base qi/std qi/hash qi/df)

    (syntax-spec

      (language qi-datascience
        #:description "Qi data science language"
        #:compose (qi-dataframe
                   qi-hash
                   qi-std)
        #:base qi-base
        #:as floe)

      (host-interface/language
        (flow f:floe))))

  (module my-application
    (require "qi-datascience.rkt"))
}

This allows users (or library authors) to compose the appropriate languages for specific domains while keeping the language as lean as possible (e.g. without pulling in every possible optimization).

Also note that the @racket[floe] nonterminal indicated in the host interface form in each of these cases indicates subexpressions by @emph{language} and entails compilation. We do not explicitly invoke compilation here as we do in the @racket[host-interface/expression] form currently used in the Qi codebase. This is because we will be leaving it to Syntax Spec to compile the syntax in the appropriate manner, which may vary depending on how the language is composed, as we will see.

@subsection{Nature of Composition}

Each language in the composition must include all of the Qi base language. Otherwise, they wouldn't recognize nested syntax that could be optimized. For example:

@codeblock{
  (~> (filter odd?) (map sqr))
}

Here, @racket[filter] and @racket[map] are forms of the @racket[qi-list] language, but @racket[~>] is a form of the @racket[qi-base] language. If the latter were not also part of @racket[qi-list], then compilation at that stage would consider this to be unknown syntax and refrain from traversing it.

@subsubsection{Language Inheritance}

In order to include the Qi base language in each of the various dialects, it would be necessary to provide some form of inheritance so that all of the languages share the same core bindings literally, and to avoid duplicate definitions.

@codeblock{
  (syntax-spec
    (nonterminal floe-list
      #:description "a list flow expression"
      #:binding-space qi

      (map f:floe-list)
      (filter f:floe-list)
      (foldl op:floe-list init:racket-expr)
      (foldr op:floe-list init:racket-expr)
      (range e:racket-expr ...+)))
}

Here, the syntax specification doesn't include any base language forms (such as @racket[esc]) as we have already declared the @racket[qi-list] language to "extend" @racket[qi-base] via:

@codeblock{
  (syntax-spec
    (language qi-list
      #:description "Qi list language"
      #:base qi-base
      floe-list
      …))
}

(as we saw above).

The @racket[qi-base] expander itself is defined as:

@codeblock{
  (syntax-spec
    (nonterminal floe-base
      #:description "a base flow expression"
      #:binding-space qi

      _
      (thread f:floe-base ...)
      (esc e:racket-expr)
      (~> f:id
          #:with spaced-f ((make-interned-syntax-introducer 'qi) #'f)
          #'(esc spaced-f))))
}

The nonterminal specifications are composed by concatenating them (which we'll designate by the notation @litchar{||}): @racket[floe-list]@litchar{||}@racket[floe-base]. The concatenation respects ordinary precedence in pattern matching, so that @racket[floe-list] expansions take precedence over @racket[floe-base].

@subsubsub*section{Extending Scoping Rules?}

The scoping rules are part of the base language and cannot be overridden by languages that inherit from it. This is already the case in languages defined with Syntax Spec -- only core forms can specify binding rules, not macros. If the ability to specify binding rules is extended to macros, then the same mechanism may suggest ways to extend it to overlying languages.

@subsubsection{Order of Compilation}

As for the compilers, we would like base language compilation to occur at the very end, if we happen to compose this language with other languages. Otherwise, we might prematurely optimize a base language expression that might have benefited from other nonlocal optimizations made possible by the compilation of subsequent languages (to the base language). Thus, the composition interface (which we'll talk about next) needs to be aware of base language compilation and code generation as distinct from compilation of the languages in the composition.

Compilation of language extensions produces base language code. For instance, compilation of @racket[qi-list] code produces @racket[qi-base] code.

@subsubsection{Mechanism of Composition}

The @racket[#:compose] syntax (just an example) above translates into an underlying language composition operation. This operation suspends judgement of invalid syntax until the very end of compilation. If a language in the composition rejects the input syntax (implying it also wasn't in the base language), then it is still passed on, verbatim, to the next language in the composition. Base language forms are likewise left uncompiled (but expanded) in providing the syntax to the next language.

When all the languages in the composition have processed the input syntax, it is forwarded to the base language compiler, followed by code generation to Racket.

The pseudocode below illustrates this composition of languages:

@codeblock{
  (struct language
    (expander
     compiler
     codegen))

  (define identity-lang
    (language (void)
              identity
              identity
              identity))

  (define (lang-comp2~> a b)
    (let ([a:expand (language-expander a)]
          [a:compile (language-compiler a)]
          [b:expand (language-expander b)]
          [b:compile (language-compiler b)])
      (λ (stx)
        (b:compile
         (b:expand
          (a:compile
           (a:expand stx)))))))

  (define (language-compose~> . ls)
    (λ (stx)
      (if (empty? ls)
          identity-lang
          (let* ([base (language-base
                        (car ls))] ; get the base language for the composition
                 [base-compile (language-compiler base)]
                 [base-codegen (language-codegen base)])
            (base-codegen
             (base-compile
              (let ([overlying-composed-lang (foldr lang-comp2~> identity-lang ls)])
                (overlying-composed-lang stx))))))))
}

@subsubsection{Multiple Inheritance?}

A language can only have one base language, and languages can only be composed when they share a common base language. Given any two languages @racket[B] and @racket[C], it is not possible for a language @racket[D] to be based on both @racket[B] and @racket[C]. Instead, what could happen is if @racket[B] and @racket[C] are both based on @racket[A] then @racket[D] could be based on the composed language @code{(B, C)}. This is a valid composition since @racket[B] and @racket[C] share a base language. In this case, @racket[D] would compile to @code{(B, C)} which compiles to @racket[A]. As @code{(B, C)} and @code{(C, B)} are explicit and distinct compositions implying different precedence in the handling of input syntax, there is no ambiguity of the kind that typically characterizes "diamond inheritance" in object-oriented programming contexts.

@section{Outlook}

@subsection{Technical Value}

@itemlist[#:style 'ordered
  @item{Safe interaction between the host and the DSL.}
  @item{Interaction between compiler passes is well-modeled and scalable.}
  @item{Compiling to different backends is straightforward.}
]

Let's look at each of these in more detail.

@subsubsection{Safe Interaction With the Host}

Compiler optimizations we perform are in terms of actual hosted DSL core forms, not matching and optimizing arbitrary patterns on host language syntax as we do today. Thus, there is no possibility of inappropriate interpretation of host language syntax or violation of host language invariants.

This also means that the optimizations are transparent and IDE-friendly, as they are performed via introspectable and documentable bindings. If there is any unexpected behavior, the user would be able to introspect the bindings and discover whether they are Qi bindings or Racket bindings, and also be able to find documentation for them that would elaborate on any optimizations performed.

This example -- representing Qi's production behavior today -- illustrates the inadvisability of optimizing host-language syntax:

@codeblock{
  #lang racket

  (require qi
           qi/list)

  (define (filter f lst)
    'hello)

  (~>> () (range 1000) (filter odd?) (map sqr) (foldl + 0)) ;=> 166666500 (!)
}

The semantics are obviously unexpected, yet introspecting the @racket[filter] binding in an IDE identifies it as the locally defined function. This is because the compiler does datum matching for optimizations (by intended design) but on host language syntax (not by intended design), and so Syntax Spec does not have an opportunity to validate that input syntax is appropriate for those optimizations.

This extreme example illustrates what is already the case even in what we might nominally consider "expected" behavior, where an expression like @racket[(~>> (filter odd?) (map sqr))], ostensibly a partial application of host language functions to list inputs, exhibits a different order of effects from these functions by virtue of deforestation. Here, too, introspecting the @racket[filter] binding identifies it as the standard binding in @racket[racket/list], yet, as we have seen, exhibiting different semantics that are not documented there, and which are not discoverable in the IDE.

@subsubsection{Scalable Interaction Between Compiler Passes}

Interaction between passes is not left to fragile convention but rather is well-modeled as explicit composition. There is no ambiguity about the handling of input syntax by composed languages. Additionally, the contract between languages is the publicly advertised core language rather than arbitrary internal representations that must be carefully synchonized. This simultaneously presents a clean interface and ensures a low maintenance burden.

@subsubsection{Ease of Compiling to Different Backends}

Flows may be compiled to ordinary functions, threads, futures, AWS Lambda Step Functions, or anything else, simply by using a different base language -- more specifically, a base language with a different code generation step. This allows different languages to have the same surface syntax with dramatically different -- and yet isomorphic -- semantics, while maximizing code reuse and maintainability.

@subsection{Social Value}

@itemlist[#:style 'unordered
  @item{Significantly broadens the applicability and scope for adoption of Syntax Spec.}
  @item{An elegant interface encourages data structure authors to contribute compiler extensions as libraries, for Qi and for Racket, in a way that is theoretically sound.}
  @item{A pleasant development experience encourages community participation. It avoids tedious social overhead in favor of fun social interactions.}
  @item{This surely opens up many new possibilities that are likely to get the community excited.}
  @item{More familiarity with Syntax Spec internals through a community project.}
  @item{It makes the Racket ecosystem more compelling, including for industry, which could bring new opportunities.}
]

@subsection{Research Value}

@itemlist[#:style 'unordered
  @item{Helps to reveal and define Syntax Spec's long term interface.}
  @item{Solving essential things now so that we have help for superficial things later.}
  @item{This theoretically sound composition of compiler extensions presents an elegant interface that is useful and perhaps novel.}
  @item{It opens up new avenues for research down the line, and possibly invites new collaborators.}
]

@section{Other Approaches}

@subsection{Hardcoded composition of passes}

Define and compose individual optimization passes in the Qi core.

@subsubsection[#:tag "hardcoded assessment"]{Assessment}

This is the simplest and the original approach. It achieves optimization in a standard architecture of passes, and also ensures a predictable semantics for the language without the possibility of ad hoc overrides. But it isn't extensible, and thus would require bespoke optimizations to be added in the Qi core, bloating the language.

In contrast, the proposed approach allows optimizations to be written in the Qi core or by third parties using the same interface, for maximum flexibility. It also retains the property of predictable semantics that can be overridden only through standard means such as shadowing of bindings.

@subsection{Composition via Racket}

Define a compiler pass as a new language (say, @racket[qi-list]) that explicitly matches all standard Qi syntax and wraps them in the usual @racket[flow] host interface macro during compilation, thus delegating standard forms to the standard Qi language in addition to layering on optimizations.

@subsubsection[#:tag "racket composition assessment"]{Assessment}

This keeps internal implementation details contained within languages and presents a clean contract between languages. It also extends language semantics by layering optimizations on top of an existing language rather than mutating it, thus presenting predictable semantics. But as the composition is essentially hardcoded, a @racket[qi-list] language would not compose with a @racket[qi-dataframe] language, and we would need to pick just one, or manually write a @racket[qi-df-list] language that includes both sets of optimizations, duplicating them and requiring independent maintenance. Additionally, if an optimization compiles to a use of the core language which could ordinarily be further optimized when considered in the surrounding context, such optimization would not occur as the use of each of the higher level languages would be wrapped with @racket[(esc ...)], and the compilation of the containing core language expression would not traverse these expressions to detect this would-be optimization.

In contrast, the proposal ensures that optimizations are composable both at the level of the overlying languages as well as at the base language level. By leveraging "inheritance," it also avoids any code duplication.

@subsection{Mutable Compile-time Registry}

Define passes in modules that could be part of the Qi core package or maintained independently. Register these passes as a require-time side-effect.

@subsubsection{Assessment}

This is the current approach and it was adopted for expediency in order to decouple short term optimization work (i.e. deforestation) from Qi core development. Yet, as a long term solution, it suffers from drawbacks:

@itemlist[#:style 'unordered
  @item{The semantics of the language are not static but may be overridden through mutation via a @racket[require] side effect. In contrast, the proposal supports overriding semantics only through the standard means of shadowing.}
  @item{Extension requires knowledge of internal intermediate representations as well as the placement of passes by other extensions. In contrast, the proposal only assumes knowledge of the public core language and does not encode any nonlocal information in the definition of optimizations.}
  @item{Optimizing host-language syntax conflates DSL invariants with those of the host language. In contrast, the proposal cleanly differentiates these so that optimizations do not transgress the host language.}
  @item{The addition of new passes in the core must take into account the entire ecosystem of optimizations, necessitating superfluous conventions. In contrast, the proposal ensures that core (and third-party) optimizations can be developed in isolation, without knowledge of other optimizations in the ecosystem.}
  @item{The technical contract between passes is unmodeled and reduces to unnecessary and troublesome social overhead. We cannot reason formally about the ecosystem of optimizations. In contrast, the proposal calls for explicit composition that defines precedence of languages, and preserves language invariants at the technical rather than social level.}
  @item{The introduction of a new pass at any time could necessitate code changes in all downstream passes. The contract of backwards compatibility is needlessly complicated. In contrast, the proposal guarantees that passes will compose with any other passes, and in any order. The only backwards compatibility contract is on the advertised core language, which thus introduces nothing new.}
]

This approach has a low upfront cost, but in the long run it causes us to spend a lot of time thinking about artificial problems and considerations, and that could prevent us from discovering worthwhile and novel things.

@section{Conclusion}

The proposed composition and inheritance scheme supports sound and scalable compiler extension for hosted languages in a way that does not suffer from the drawbacks of competing approaches and opens up many interesting avenues of future exploration.
