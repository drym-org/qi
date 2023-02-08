* Sid designed the language
* Sid wrote the initial implementation
* Sid was invited to give a talk at RacketCon
* Jay gave feedback on Sid's talk
* Sid gave a talk at RacketCon
* Jay led the Q&A for the talk
* Jay suggested improvements to switch
* Sid implemented improvements to switch
* Ben used and advocated for Qi
* Cassie used and advocated for Qi
* Stephen used and advocated for Qi
* Ben solved Advent of Code using Qi
* Ben provided a design example to motivate adding closures (the clos form) to Qi
* Soegaard suggested the name clos for this form
* Jesse and William suggested writing a tutorial
* Stephen wrote a quickscript for entering unicode in DrRacket
* Stephen suggested distributing a Qi template using racket templates
* Sid wrote an interactive tutorial using racket templates
* Laurent added a quickscript for interactive evaluation in DrRacket to support the Qi tutorial
* Stephen suggested decomposing the package into lib/test/doc packages for more flexible development and distribution
* Sid decomposed the package into lib/test/doc packages
* Sid added a flow-oriented debugger
* jo-sm reported an installation issue
* Stephen reported a broken link in the documentation
* Sid fixed some bugs in switch
* Sid designed a simple macro extensibility based on prefix matching, to allow users to extend the syntax of the language in a rudimentary way
* Sam provided an implementation for the prefix matching macro extensibility scheme
* Michael suggested many options for proper macro extensibility
* Michael and Sid implemented "first class" macro extensibility (based on Michael et al's paper), allowing users to seamlessly extend the syntax of the language
* Ben reported a confusing error message in the threading form and suggested a way to handle it
* Sid implemented Ben's suggested error message fix
* Stephen suggested the idea of a Qi-themed event
* Sid organized the Qi design challenge
* 1e1001 provided an illustrative example to motivate design improvements to the `feedback` form of the language
* Sid improved the design of `feedback`
* Ben reviewed the PR improving the design of `feedback`
* Nia suggested restricting fancy-app's scope in Qi to avoid tricky bugs in handling user input
* Sid restricted fancy-app to just the fine-grained application form
* Nia reviewed the fancy-app PR
* Ben pointed out that fanout does not accept arbitrary Racket expressions for N
* Ben suggested an optimized implementation for fanout
* Sid modified fanout to support arbitrary expressions for N and have an optimized implementation
* Ben reviewed the fanout PR
* Ben added partition, a generalized version of the sieve form
* Ben optimized the partition implementation
* Sid reviewed the partition PR
* Stephen modified the package config so that Qi appears in the languages section of the docs
* Sid set up CI for the project repository
* Sam provided a recipe for hosting backup documentation in case the package index is unavailable
* Sid added the backup docs workflow following Sam's recipe
* Sid added benchmarking scripts
* Sid added performance benchmarking to CI
* Michael did an audit of the performance benchmarks for accuracy
* Sid fixed the benchmarks according to the audit
* Michael and Sid refactored the core macro into separate expansion and compilation stages
* Nia identified an elusive bug causing performance degradation in the threading form
* Michael identified a hygiene issue related to the same bug that could have caused other bugs in the future
* Ben reduced the number of dependencies
* Bogdan wrote a dependency profiler tool to identify heavy dependencies
* Sarna suggested a way to measure load-time latency
* Sid wrote a script to measure load-time latency following that approach
* Ben reviewed the load-time latency PR
* Ben used the tools to identify and remove all heavy dependencies and dramatically reduce load-time latency
* Ben modified the benchmarks runner config to avoid reporting success when it failed
* Sorawee and Jack suggested using indirect documentation links to reduce build times
* Soegaard suggested some improvements to reduce memory consumption in building docs
* Noah added the ability to support the _ template in the function position
* Noah added support for keyword arguments to add bindings in lambda forms of the language
* Noah fixed some formatting and typos in the docs
* Noah updated uses of deprecated macro form ~or to ~or*
* Noah removed the unused let/flow and let/switch macros
* Noah improved the organization of some tests
* Noah significantly improved the performance of any?, all?, and none?
* Noah wrote the first library extending Qi functionality
* Anonymous suggested creating a wiki for Qi
* Sid created a wiki
* Sid wrote a Developer's Guide containing developer documentation
* Sid wrote docs for Qi
* Michael and Sid started a weekly meetup for the project
* Sid migrated the repo to an organization account
* The project benefited from general support from the Racket community
