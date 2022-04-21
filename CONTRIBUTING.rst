Contributing
============

.. contents:: :depth: 1

Installing Qi Locally
---------------------

You could install it either in a default scope such as User scope (meaning it will available to the current user of the operating system), or, if you prefer, you could also install it in a virtual environment specific to the project. These options are covered below, in turn.

Installing in User Scope
~~~~~~~~~~~~~~~~~~~~~~~~

Uninstall any version of Qi you already have
^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^

.. code-block:: bash

  raco pkg remove --force qi

Install from source
^^^^^^^^^^^^^^^^^^^

After cloning the repo and changing to the repo directory:

.. code-block:: bash

  make install

Installing in a Virtual Environment
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

You may prefer this option if you already have a version of Qi installed in the User scope and would prefer to do development in an isolated environment. Remember, if you go with this option, you will need to activate the virtual environment (described below) before you can use the development workflows below.

Install raco-pkg-env
^^^^^^^^^^^^^^^^^^^^

.. code-block:: bash

  raco pkg install raco-pkg-env

Clone the Qi Repo
^^^^^^^^^^^^^^^^^

.. code-block:: bash

  git clone git@github.com:countvajhula/qi.git
  cd qi

Create and Activate the Virtual Environment
^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^

.. code-block:: bash

  raco pkg-env _env
  source _env/activate.sh

Install Qi Into the Virtual Environment
^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^

.. code-block:: bash

  make install

Development Workflows
---------------------

Run ``make help`` or simply ``make`` to see all of the options here. The main ones are summarized below.

Dev Loop
~~~~~~~~

Rebuilding
^^^^^^^^^^

.. code-block:: bash

  make build

Running Tests
^^^^^^^^^^^^^

Run all tests

.. code-block:: bash

  make test

Run tests for a specific module (example - run ``make help`` or simply ``make`` for more options)

.. code-block:: bash

  make test-threading

Running Profilers
^^^^^^^^^^^^^^^^^

You'd typically only need these when you're optimizing performance in general or the implementation of a particular form.

Run all profilers

.. code-block:: bash

  make profile

Run just the profilers for individual forms

.. code-block:: bash

  make profile-forms

Run just the competitive benchmarks against Racket

.. code-block:: bash

  make profile-base

Docs Loop
~~~~~~~~~

The docs are in Scribble files in ``qi-doc/``. After making any additions or changes:

Rebuilding
^^^^^^^^^^

.. code-block:: bash

  make build-docs

Viewing Docs
^^^^^^^^^^^^

.. code-block:: bash

  make docs

Release Workflow (Steps for Maintainer)
---------------------------------------

Build package, docs, and check dependencies
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

.. code-block:: bash

  make build-all

Check dependencies
~~~~~~~~~~~~~~~~~~

.. code-block:: bash

  make check-deps

Cutting a New Release
~~~~~~~~~~~~~~~~~~~~~

Bump the version in info.rkt and make a fresh commit

.. code-block:: racket

  (define version "i.j.k") ; numbers corresponding to major.minor.patch

Tag the release commit

.. code-block:: bash

  git tag -n<NUM>  # list existing tags and annotations; if specified, NUM configures verbosity
  git tag -a <new version number> -m "<release message>"  # or leave out -m to enter it in Vim

Push the changes including the new tag to origin

.. code-block:: bash

  git push --follow-tags  # push new tag to remote
