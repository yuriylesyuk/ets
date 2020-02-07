# ETS Edge Trace Session CLI Tool

This tool is useful for creating and downloading TRACE xml files for Apigee Edge, both SaaS and OPDK.


# Troubleshooting using ets

One of the use cases is for identifying hard-to-catch proxy problems. 

A typical usage for this scenario would be to automate sampling of traces. 

Example, For each captured trace identify requests that take more than 30 seconds. We want to create a script that would parse trace files and identify times spent in each request and each policy.

Make ets utility invoked in a loop and let it run... until you catch your culprit.

trace-policyelapsedtimes.awk is an awk script that filters out debug request id, policy name, and policy duration.

WARNING, it is a gawk awk's dialect [for regex]!

Command:

`
$ awk -f trace-policyelapsedtimes.awk trace-1581013540920.xml | awk '$3 > 30'
`

will print out any policy(ies), whose duration is more than 30 seconds.
