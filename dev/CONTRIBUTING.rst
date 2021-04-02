Dev Workflow
============

1. Build source

.. code-block:: bash

  make build

2. Run tests

.. code-block:: bash

  make test

Docs Workflow
=============

3. Build docs

.. code-block:: bash

  make build-docs

4. View docs

.. code-block:: bash

  make docs

Release Workflow (Steps for Maintainer)
=======================================

5. Build package, docs, and check dependencies

.. code-block:: bash

  make build-all

6. Check dependencies

.. code-block:: bash

  make check-deps

7. When you're ready to cut a new release, bump the version in info.rkt and make a fresh commit

.. code-block:: racket

  (define version "i.j.k") ; numbers corresponding to major.minor.patch

8. Tag the release commit

.. code-block:: bash

  git tag -n<NUM>  # list existing tags and annotations; if specified, NUM configures verbosity
  git tag -a <new version number> -m "<release message>"  # or leave out -m to enter it in Vim

9. Push the changes including the new tag to origin

.. code-block:: bash

  git push --follow-tags  # push new tag to remote
