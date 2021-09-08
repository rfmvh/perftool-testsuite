# perftool-testsuite

Author: Michael Petlan <mpetlan@redhat.com>

FOR CONTRIBUTING, PLEASE USE git format-patch AND git send-email.
YOU HAVE A HIGHER CHANCE YOUR PATCH GETS REVIEWED THAN WITH PULL
REQUESTS! THANK YOU.

Introducing a new testsuite for perf builtin commands. The testsuite
should cover all the perf's builtin commands, their options and use-
cases in various situations.


The goals:

  * Structured and standalone

	The testsuite should run on an usual Linux distribution, against
	the perf tool installed from packages or just built.   The tests
	should be organized in subtests  which include/use some "common"
	stuff, but are basically standalone.

	These subtests are in base_<subtest> directories that contain:

		* setup.sh
			--> should be run if something needs to be set up

		* test_*.sh
			--> various subtests

		* cleanup.sh
			--> to be run for cleaning up

		* settings.sh
			--> should contain a name of the test and possibly other
			constants and settings if necessary
			--> designed to be sourced

	There is a separate test-driver that runs the testcases.

	All the common stuff is stored in common directory and it can be
	sourced by each testcase or by hand when necessary.

	The shell scripts  in base_<TEST_NAME> should return 0 or 1 when
	pass or fail in order to report the results up.  They also might
	use common print_results and print_overall_results functions.


  * Extensible

	Adding new testcases should be as easy as possible, no matter if
	a whole test (new builtin command, or whatever) is added or just
	another base_<TEST_NAME>/test_something.sh.


  * Easy investigation and reproduction of the failures

	When a test fails,  the QE needs to be able to find what exactly
	went wrong, narrow the problem down,  be able to reproduce it by
	hand with a minimal reproducer.  That should be possible even if
	the QE is new to the component and does not know the tests.

	When you see a failure, you should be able to go directly to the
	proper testcase and reproduce the failure in shell manually.

	Some tests need the setup.sh first, but even that is still easy.

	Also investigation of what went wrong in the finest commands is
	easy, since the log should give a hint which line did not match
	or which regexp was not found etc.


  * Stable

	The test should be stable too, we need to set the result checks
	to be robust, to be able to detect bugs, but not to fail due to
	random dust and known issues. Some XFAIL and XPASS mechanism is
	necessary to be introduced too.


  * Configurable

	Since sometimes a deep test is what we want,  sometimes we need
	just a quick smoke test,  a basic level-of-detail configuration
	is necessary. This is done by "common/parametrization.sh" which
	is designed to be sourced by the tests and config variables can
	be used there.


  * Multiarch

	The testsuite should be able to run on non-x86 archs as well.


