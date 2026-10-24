%%raw(`import './setup.mjs'`)

/* Suites with asynchronous tests. A separate entry from `Tests.res`, whose
   synchronous runner ends the process once it reports. */
Zekr.runAsyncSuites([Resource_test.suite, DevtoolsPanel_test.suite])->ignore
