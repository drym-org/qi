* The language was designed
* The initial implementation was written
* The initial author was invited to give a talk at RacketCon
* The initial author received feedback on drafts of the talk
* The initial author gave a talk at RacketCon
* A Q&A was held after the talk
* Improvements to the switch form were suggested
* Improvements to switch were implemented
* An early adopter advocated for the project
* An early adopter advocated for the project
* An early adopter advocated for the project
* Advent of Code was solved using Qi
* A design example was provided to motivate adding closures (the clos form) to Qi
* The name clos was suggested for this form
* There was a suggestion to write a tutorial
* A quickscript for entering unicode in DrRacket was written
* There was a suggestion to distribute a Qi template using racket templates
* An interactive tutorial was written using racket templates
* A quickscript for interactive evaluation in DrRacket was added to support the Qi tutorial
* There was a suggestion to decompose the package into lib/test/doc packages for more flexible development and distribution
* The package was decomposed into lib/test/doc packages
* A flow-oriented debugger was added
* An installation issue was reported
* A broken link in the documentation was reported
* Some bugs in switch were fixed
* A simple macro extensibility based on prefix matching was designed
* An implementation for the prefix matching macro extensibility scheme was provided
* Many options for proper macro extensibility were suggested
* "First class" macro extensibility was implemented, allowing users to seamlessly extend the syntax of the language
* A confusing error message in the threading form was reported and a way to handle it was suggested
* The suggested error message fix was implemented
* The idea of a Qi-themed event was suggested
* The Qi design challenge was organized
* An example implementation to motivate design improvements in feedback was provided
* The design of feedback was improved
* The feedback PR was reviewed
* There was a suggestion to restrict fancy-app's scope in Qi to avoid tricky bugs in handling user input
* fancy-app was restricted to just the fine-grained application form
* The fancy-app PR was reviewed
* It was pointed out that fanout does not accept arbitrary Racket expressions for N
* An optimized implementation was suggested for fanout
* fanout was modified to support arbitrary expressions for N and have an optimized implementation
* The fanout PR was reviewed
* partition was added, which is a generalized version of the sieve form
* The partition implementation was optimized
* The partition PR was reviewed
* The package config was modified so that Qi appears in the languages section of the docs
* CI was set up for the project repository
* A recipe for hosting backup documentation in case the package index is unavailable was provided
* The backup docs workflow following the recipe was added
* Benchmarking scripts were added
* Performance benchmarking was added to CI
* The performance benchmarks were audited for accuracy
* The benchmarks were fixed according to the audit
* The core macro was refactored into separate expansion and compilation stages
* An elusive bug was identified that was causing performance degradation in the threading form
* A hygiene issue related to the same bug was identified that could have caused other bugs in the future
* The number of dependencies was reduced
* A dependency profiler tool was written to identify heavy dependencies
* A way to measure load-time latency was suggested
* A script to measure load-time latency following that approach was written
* The load-time latency PR was reviewed
* These tools were used to identify and remove all heavy dependencies and dramatically reduce load-time latency
* The benchmarks runner config was modified to avoid reporting success when it failed
* There was a suggestion to use indirect documentation links to reduce build times
* Some improvements were suggested to reduce memory consumption in building docs
* The ability to support the _ template in the function position was added
* Support for keyword arguments to add bindings in lambda forms of the language was added
* Some formatting and typos in the docs were fixed
* Uses of deprecated macro form ~or were updated to ~or*
* The unused let/flow and let/switch macros were removed
* The organization of some tests was improved
* The performance of any?, all?, and none? were significantly improved
* The first library extending Qi functionality was written
* There was a suggestion to create a wiki for Qi
* The wiki was created
* A Developer's Guide containing developer documentation was written
* Documentation was written for Qi
* A weekly meetup for the project was started
* The repo was migrated to an organization account
* The project benefited from general support from the Racket community
