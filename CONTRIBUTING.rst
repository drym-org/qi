Contributing
============

.. contents:: :depth: 2

Installing Qi Locally
---------------------

You could install it either in a default scope such as User scope (meaning it will available to the current user of the operating system), or, if you prefer, you could also install it in a virtual environment specific to the project. These options are covered below, in turn.

Installing in User Scope
~~~~~~~~~~~~~~~~~~~~~~~~

For most users, this will be the most straightforward installation. Using this option means that Qi will be installed so that it is linked directly to the cloned instance of the Git repo on your local machine. It means that any changes you make there will be reflected in all code on your machine that depends on Qi. Likewise, updating Qi would just be a matter of ``git pull``.

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

[This option is **experimental** and the details are yet to be worked out, as virtual environments aren't commonly used in Racket at the moment. The instructions below aren't quite right, so if you'd prefer to do it this way, then please see the relevant `discussion on the raco-pkg-env repo <https://github.com/samdphillips/raco-pkg-env/issues/8>`__ first. TL;DR - for now, you can probably just set the ``PLTUSERHOME`` environment variable to approximate a virtual environment.]

This uses the `raco-pkg-env <https://github.com/samdphillips/raco-pkg-env>`_ package to create and manage virtual environments in Racket. You may prefer this option if you already have a version of Qi installed in the User scope and would prefer to do development in an isolated environment. Remember, if you go with this option, you will need to activate the virtual environment (described below) before you can use the development workflows below.

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
`````````````

.. code-block:: bash

  make test

Run tests for a specific module (example - run ``make help`` or simply ``make`` for more options)
`````````````````````````````````````````````````````````````````````````````````````````````````

.. code-block:: bash

  make test-threading

Running Profilers
^^^^^^^^^^^^^^^^^

You'd typically only need these when you're optimizing performance in general or modifying the implementation of a particular form.

Since the profilers are just Racket modules and aren't part of any package, you will need to ensure that the dependencies are installed on your own. Specifically, you will need the following packages installed before the make targets below will work:

.. code-block:: bash

  cli
  adjutor
  collections-lib

Some of these are dependencies of Qi packages, so you should have them already.

Run all profilers
`````````````````

.. code-block:: bash

  make profile

Run just the competitive benchmarks against Racket
``````````````````````````````````````````````````

.. code-block:: bash

  make profile-competitive

Run just the profilers for forms of the language
````````````````````````````````````````````````

.. code-block:: bash

  make profile-forms

Run just the profilers for selected forms
`````````````````````````````````````````

.. code-block:: bash

  make profile-selected-forms

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
