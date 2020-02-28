---
title: Some Notes on Apache Spark Memory Management
description: Some notes on Apache Spark Memory management
category: tech
image: "/assets/img/spark.png"
---

## Important configurations:
* <span style="color: darkred">spark.executor.memory</span> – Size of memory to use for each executor that runs the task.
* <span style="color: darkred">spark.executor.cores</span> – Number of virtual cores.
* <span style="color: darkred">spark.driver.memory</span> – Size of memory to use for the driver.
* <span style="color: darkred">spark.driver.cores</span> – Number of virtual cores to use for the driver.
* <span style="color: darkred">spark.executor.instances</span> – Number of executors. Set this parameter unless spark.dynamicAllocation.enabled is set to true.
* <span style="color: darkred">spark.default.parallelism</span> – Default number of partitions in resilient distributed datasets (RDDs) returned by transformations like join, reduceByKey, and parallelize when no partition number is set by the user
* <span style="color: darkred">spark.sql.execution.arrow.enabled</span> - Enable optimization for panda dataframe
* <span style="color: darkred">spark.files.ignoreCorruptFiles</span> - Ignore corrupt files
* <span style="color: darkred">spark.sql.files.ignoreCorruptFiles</span> - Ignore corrupt files
* <span style="color: darkred">spark.executor.extraJavaOptions</span> - Other Java options like garbage collection for executors
* <span style="color: darkred">spark.driver.extraJavaOptions</span> - Other Java options like garbage collection for drivers

## Sample Calculations:

Consider an EMR cluster with 1 master - 25 slaves running c5.18xlarge instance. Each instance comes with 72vCPU, 144 GiB Memory.

* <span style="color: darkred">spark.executor.cores</span> = number of virtual cores per executor. Recommendation is 5
  > spark.excutor.cores = 5
* Number of executors per instance = (total number of virtual cores per instance - 1)/ spark.executors.cores<br>
	 > Number of executors per instance = (72 - 1) / 5 = 14
	 
	 Total executor memory = total RAM per instance / number of executors per instance<br>
	 > Total executor memory = 144 / 14 = 10 (round down)
	 
	 <span style="color: darkred">spark.executors.memory</span> = total executor memory * 0.9
	 > spark.executors.memory = 10 * 0.9 = 9g
	 
* <span style="color: darkred">spark.executor.memoryOverhead</span> = total executor memory * 0.10
   > spark.excutor.memoryOverhead = 10 * 0.1 = 1g
* <span style="color: darkred">spark.driver.memory</span> = spark.executors.memory
   > spark.driver.memory = 9g
* <span style="color: darkred">spark.driver.cores</span>= spark.executors.cores
   > spark.driver.cores = 5
* <span style="color: darkred">spark.executor.instances</span> = (number of executors per instance * number of core instances) minus 1 for the driver
   > spark.executor.instances = 14 * 25 - 1 = 349
* <span style="color: darkred">spark.default.parallelism</span> = spark.executor.instances * spark.executors.cores * 2
   > spark.default.parallelism = 349 * 5 * 2 = 3490
* <span style="color: darkred">spark.executor.extraJavaOptions</span>
   > spark.executor.extraJavaOptions = -XX:+UseG1GC -XX:+UnlockDiagnosticVMOptions -XX:+G1SummarizeConcMark -XX:InitiatingHeapOccupancyPercent=35 -verbose:gc -XX:+PrintGCDetails -XX:+PrintGCDateStamps -XX:OnOutOfMemoryError='kill -9 %p'
* <span style="color: darkred">spark.driver.extraJavaOptions</span>
   > spark.executor.extraJavaOptions = -XX:+UseG1GC -XX:+UnlockDiagnosticVMOptions -XX:+G1SummarizeConcMark -XX:InitiatingHeapOccupancyPercent=35 -verbose:gc -XX:+PrintGCDetails -XX:+PrintGCDateStamps -XX:OnOutOfMemoryError='kill -9 %p'

## Sources:
* [https://aws.amazon.com/blogs/big-data/best-practices-for-successfully-managing-memory-for-apache-spark-applications-on-amazon-emr/](https://aws.amazon.com/blogs/big-data/best-practices-for-successfully-managing-memory-for-apache-spark-applications-on-amazon-emr/)
* [https://spark.apache.org/docs/latest/sql-pyspark-pandas-with-arrow.html](https://spark.apache.org/docs/latest/sql-pyspark-pandas-with-arrow.html)