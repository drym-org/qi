#lang scribble/manual
@require[scribble/manual
         @for-label[qi
                    racket]]

@title[#:tag "Flowing_with_the_Flow"]{Input Methods}

If your code flows but you don't, then we're only halfway there. This chapter covers some UX considerations related to programming in Qi, so that expressing @tech{flows} in code is just a thought away.

The main thing is, you want to ensure that these forms have convenient keybindings:

@tabular[#:sep @hspace[1]
         (list (list @racket[☯])
               (list @racket[~>])
               (list @racket[-<])
               (list @racket[△])
               (list @racket[▽])
               (list @racket[⏚]))]

Now, it isn't just about being @emph{able} to enter them, but being able to enter them @emph{without effort}. This makes a difference, because having convenient keybindings for Qi is less about entering unicode conveniently than it is about @emph{expressing ideas} economically, just as having evocative symbols in Qi is less about brevity and more about appealing to the intuition. After all, as the old writer's adage goes, "show, don't tell."

Some specific suggestions are included below for commonly used editors and operating systems.

@section{Unicode Support}

Some of the following sections cover entering unicode characters in various editors, but if the font you're using doesn't have full unicode support (e.g. on Linux), these characters may render only as nondescript boxes. In this case, consult the documentation for your operating system to discover fonts with unicode support (for instance, if your OS happens to be Arch Linux, the @hyperlink["https://wiki.archlinux.org/title/Fonts#Font_packages"]{font documentation for that system}). One widely available collection of such fonts is @hyperlink["https://fonts.google.com/noto"]{Noto}.

@section{DrRacket}

Stephen De Gabrielle created a @seclink["top" #:indirect? #t #:doc '(lib "quickscript/scribblings/quickscript.scrbl")]{quickscript} for convenient entry of Qi forms: @seclink["top" #:indirect? #t #:doc '(lib "qi-quickscripts/scribblings/qi-quickscripts.scrbl")]{Qi Quickscripts}. This option is based on using keyboard shortcuts to enter exactly the form you need.

Laurent Orseau's @seclink["top" #:indirect? #t #:doc '(lib "quickscript-extra/scribblings/quickscript-extra.scrbl")]{Quickscript Extra} library includes the @hyperlink["https://github.com/Metaxal/quickscript-extra/blob/master/scripts/complete-word.rkt"]{complete-word} script that allows you to define shorthands that expand into pre-written templates (e.g. @racket[(☯ \|)], with @racket[\|] indicating the cursor position), and includes some Qi templates with defaults that you could @seclink["Shadow_scripts" #:indirect? #t #:doc '(lib "quickscript/scribblings/quickscript.scrbl")]{customize further}. This option is based on short textual aliases with a common keyboard shortcut.

There are also a few general unicode entry options, including a quickscript for @hyperlink["https://gist.github.com/Metaxal/c328dca7849018388f792094f8e0895c"]{unicode entry in DrRacket}, and @hyperlink["https://docs.racket-lang.org/the-unicoder/index.html"]{The Unicoder} by William Hatch for system-wide unicode entry. While these options are useful and recommended, they are not a substitute for the Qi-specific options above but a complement to them.

Use any combination of the above that would help you express yourself economically and fluently.

@section{Vim/Emacs}

@subsection{Keybindings}

For Vim and Emacs Evil users, here are suggested keybindings for use in insert mode:

@tabular[#:sep @hspace[1]
         (list (list @bold{Form} @bold{Keybinding})
               (list @racket[☯] @code{C-;})
               (list @racket[~>] @code{C->})
               (list @racket[-<] @code{C-<})
               (list @racket[△] @code{C-v})
               (list @racket[▽] @code{C-V})
               (list @racket[⏚] @code{C-=}))]

For vanilla Emacs users, I don't have specific suggestions since usage patterns vary so widely. But you may want to define a custom @hyperlink["https://www.emacswiki.org/emacs/InputMethods"]{input method} for use with Qi (i.e. don't rely on the LaTeX input method, which is too general, and therefore isn't fast), or possibly use a @hyperlink["https://www.emacswiki.org/emacs/Hydra"]{Hydra}.

@subsection{Indentation}

In Racket Mode for Emacs, use the following config to indent Qi forms correctly:

@codeblock{
    (put 'switch 'racket-indent-function 1)
    (put 'switch-lambda 'racket-indent-function 1)
    (put 'on 'racket-indent-function 1)
    (put 'π 'racket-indent-function 1)
    (put 'try 'racket-indent-function 1)
}
