#lang info

(define version "2.0")
(define collection "qi")
(define deps '("base"))
(define build-deps '("scribble-lib"
                     "scribble-abbrevs"
                     "scribble-math"
                     "racket-doc"
                     "sandbox-lib"
                     "from-template"
                     "quickscript"
                     "quickscript-extra"
                     "Qi-Quickscripts"
                     "tmux-vim-demo"
                     "threading-doc"
                     "deta-doc"
                     "sawzall-doc"
                     "megaparsack-doc"
                     "social-contract"
                     "debug"
                     "mischief"
                     "fancy-app"
                     "math-lib"
                     "metapict"
                     "qi-lib"
                     "qi-probe"
                     "relation"))
(define scribblings '(("scribblings/qi.scrbl" (multi-page) (language))))
(define clean '("compiled" "doc" "doc/qi"))
