#SresSQL 1.0 - Overview

This  visual  studio project  will build on  all   versions   of SQL  Server  from  2014
onwards, its  aim is to  provide a  test harness which can  be  used to execute up  to 2
different  user supplied stored  procedures  concurrently using thread counts  specified
by a user supplied lower and upper boundaries.	

The following statistics are gathered for each execution:

- Start and end times
- Throughput in transactions per second
- Top 5 wait statistics by percentage
- Top 5 latch statistics by latch sleep time
- Top 5 spinlock statistics by spins 

The test harness is encapsulated by two objects:

- usp_StresSQL
- StresSQLStats

To illustrate how the test harness works, this example:

```
EXECUTE @RC = [dbo].[usp_StresSQL] 
  @Test            = 'LMax disk no sequence push and pull'
 ,@StartThread     = 1
 ,@EndThread       = 3
 ,@Procedure1      = '[dbo].[usp_LmaxPushDiskNoSequence]'
 ,@TransactionsPerThread = 1000
GO
```

will execute the [dbo].[usp_LmaxPushDiskNoSequence] procedure with 1000 messages pushed
per thread, the harness will carry this out with a single thread to begin with, after
this has executed StresSQLStats will be populated with execution, wait, latch and spinlock
statistics. The harness will continue to carry out the exact same oprtation, but for two
threads and then finally three.
 
The sample objects accompanying the project include memory optimised tables which is why 
the dependancy on SQL Server from 2014 onwards exists.

Going forwards, all the code that accompanies by blog will be added to this visual studio
project.
 
#What The Project Contains
 
 - Core stress test harness objects:

 usp_StresSQL
 StresSQLStats

 - Stored procedures for creating database engine stress using singleton inserts:

 __usp_InsertBitReverse__
 Performs singelton inserts into a clustered index using a *bit reversed* key.
 
 __usp_InsertGuid__    
 Performs singelton inserts into a clustered index using a *GUID* key.
 
 __usp_InsertHashPart__  
 Performs singelton inserts into a partitioned clustered index using a *hash* key.
  
 __usp_InsertSpid__    
  Performs singelton inserts into a clustered index using a key based on *@@SPID offset* ( @@SPID * 10000000000 ).
 
 - Procedures for pushing messages into a disk based queue based on the LMax disruptor pattern using a sequence object for slot id generation

 __usp_LMaxDiskInit__          
 Procedure to set reference count to 0 for each queue slot prior to each test.
 
 __usp_LmaxPushDiskSequence__      
 Main procedure to run the test, it invokes usp_PushMessageDiskSequence from within a loop.
 
 __usp_PushMessageDiskSequence__    
 Procedure to push individual messages into the queue.

 - NUMA aware procedures for pushing messages into a disk based queue based on the LMax disruptor pattern using a sequence object for slot id generation

 __usp_LMaxDiskNumaInit__        
 Procedure to set reference count to zero for each slot in queues.
 
 __usp_LmaxPushDiskNumaSequence__    
 Main push procedure.
 
 __usp_PushMessageDiskSequenceNode0__  
 Procedure to push messages into NUMA node 0 queue clustered index.
 
 __usp_PushMessageDiskSequenceNode1__  
 Procedure to push messages into NUMA node 1 queue clustered index.
 
 - Procedures for pushing messages into a disk based queue based on the LMax disruptor pattern using an in-memory table for slot id generation

 __usp_LMaxDiskInit__          
 Procedure to set reference count to 0 for each queue slot prior to each test.
 
 __usp_LmaxPushDiskNoSequence__     
 Main procedure to run the test, it invokes usp_PushMessageDiskNoSequence from within a loop.
 
 __usp_PushMessageDiskNoSequence__   
 Procedure to push individual messages into the queue.
 
 __usp_GetPushSlotId__         
 Procedure to obtain the id for a slot to push a message into

 - NUMA aware procedures for pushing messages into a disk based queue based on the LMax disruptor pattern using an in-memory table for slot id generation

 __usp_LMaxDiskNumaInit__        
 Procedure to set reference count to zero for each slot in queues.
 
 __usp_LmaxPushDiskNumaNoSequence__  
 Main push procedure.
 
 __usp_GetPushSlotIdNode0__       
 Procedure to obtain the slot id for pushing messages into queue for NUMA node 0.
 
 __usp_GetPushSlotIdNode1__     
 Procedure to  obtain the slot id forpushing messages into queue for NUMA node 1.

 __usp_PushMessageDiskNoSequenceNode0__
 Procedure to push messages into NUMA node 0 queue clustered index.
 
 __usp_PushMessageDiskNoSequenceNode1__
 Procedure to push messages into NUMA node 1 queue clustered index.
 
 - Procedures for pushing messages into a in-memory queue based on the LMax disruptor pattern using an in-memory table for slot id generation
 
 __usp_PushMessageImOltpSequence__  
 
 __usp_PushMessageImOltpNoSequence__  
 
##How To Deploy The Project

1. A SQL Server 2014 or 2016 instance is required in order to deploy the StresSQL project

2. The StresSQL harness requires the ability to run xp_cmdshell, as this provides access to the underlying operating system, 
   this should not be enabled on production instances. 

```
EXEC sp_configure 'show advanced options', 1; 
GO 
-- To update the currently configured value for advanced options. 
RECONFIGURE; 
GO 
-- To enable the feature. 
EXEC sp_configure 'xp_cmdshell', 1; 
GO 
-- To update the currently configured value for this feature. 
RECONFIGURE; 
GO
```

3. Enable CLR integration:

```
sp_configure 'show advanced options', 1; 
GO 
RECONFIGURE; 
GO 
sp_configure 'clr enabled', 1; 
GO 
RECONFIGURE; 
GO 
```

4. Publish the project, on a MacBook Pro (Intel i7 and 16GB of memory) with Windows 10 running
   under bootcamp and SQL Server 2016, the project takes around 17.5 minutes to run,the bulk of this
   time is that spent populating the queue tables (MyQLMax, MyQLMaxNode0 and MyQLMaxNode1) with empty
   slots.

##How To Use The Stress Test Harness

Use the [dbo].[usp_StresSQL] stored procedure to invoke the test harness:

```
EXECUTE @RC = [dbo].[usp_StresSQL] 
  @Test
 ,@StartThread
 ,@EndThread
 ,@Procedure1
 ,@Procedure2
 ,@InitProcedure
 ,@TransactionsPerThread
 ,@CommitBatchSize
GO
```

rows representing execution stats for a test are inserted into the StresSQLStats table, it
is assumed that this resides in the same database that the test is performed against. The input parameters
this stored procedure takes are as follows:

 Parameter          | Description                 | Mandatory (Y/N)   |
 ---------------------------- | ------------------------------------------- | -------------------- |
 @Test            | Name of the test to run.          |      Y     |
 @StartThread        | Start number of the number of threads to run the test with.             |        Y   |
 @EndThread         | Start number of the number of threads to runthe test with.              |Y           | 
 @Procedure1         | Name of the first procedure to run.     |      Y     |
 @Procedure2         | Name of the second procedure to run     |      N     |
 @InitProcedure       | Test initialisation procedure        |      N     |
 @TransactionsPerThread   | Number of transactions to run per thread, equates to rows to insert for usp_Insert procedures and messages for the usp_LMax procedures, defaults to 200,000       |N           |
 @CommitBatchSize      | Number of items to batch together per commit, defaults to 1 and is always 1 for the LMax procedures.          |  N         |

The test harness assumes:

1. The objects and code being tested reside in the same database as usp_StresSQL and the
  StresSQLStats table.

2. Both the buffer pool and plan cache should be cold prior to each test.

3. All log file virtual log files should be in a reusable state prior to each test.

4. All queue tables have 4,000,000 message slots.

##Examples:

- Lmax disk based table push and pull working at the same time with 1 and then 2 threads, with 1000
  messages pushed and pulled

```
USE [StresSQL]
GO

DECLARE @RC int

EXECUTE @RC = [dbo].[usp_StresSQL] 
  @Test         = 'LMax disk no sequence push and pull'
 ,@StartThread      = 1
 ,@EndThread       = 2
 ,@Procedure1      = '[dbo].[usp_LmaxPushDiskNoSequence]'
 ,@Procedure2      = '[dbo].[usp_LmaxPopDiskNoSequence]'
 ,@TransactionsPerThread = 1000
GO
```

- Lmax disk based table push *only* with 1 and then 2 threads, with 1000 messages pushed per thread

```
USE [StresSQL]
GO

DECLARE @RC int

EXECUTE @RC = [dbo].[usp_StresSQL] 
  @Test         = 'LMax disk no sequence push and pull'
 ,@StartThread      = 1
 ,@EndThread       = 2
 ,@Procedure1      = '[dbo].[usp_LmaxPushDiskNoSequence]'
 ,@TransactionsPerThread = 1000
GO
```

- Singleton insert with cluster key based on a @@SPID offset

```
USE [StresSQL]
GO

DECLARE @RC int

EXECUTE @RC = [dbo].[usp_StresSQL] 
  @Test         = 'Singleton INSERT stress test '
 ,@StartThread      = 1
 ,@EndThread       = 2
 ,@Procedure1      = '[dbo].[usp_InsertSpid]'
 ,@TransactionsPerThread = 1000
GO
```

##A Note On Using The NUMA Push/Pop Procedures

When using the NUMA push and pop procedures, for example, if using the stored procedure:

usp_LmaxPushDiskNumaNoSequence

you must use its pop counterpart:

usp_LmaxPopDiskNumaNoSequence

and also the NUMA init procedure:

usp_LMaxDiskNumaInit

##Suggestions For Configuring SQL Server Prior To Tesing

1. Have at least one file in the file group FG_01 per logical processor, or two if your storage is high
  performance flash based.

2. To investigate spinlock pressure, enable delayed durability, otherwise all you will observe is WRITELOG 
  waits, unless you are using memory mapped log write IO to an NVDIMM via Windows 2016 DAX.

3. If delayed durability is being used with low latency flash storage, consider turning off the 
   multi-threaded log writer via trace flag 9038, otherwise you may see an excessive amount of spinlock
   activity on the LOGFLASHQ and LOGCACHE_ACCESS spinlocks, note that this only applies to SQL Server
   2016 onwards.

4. For server with two sockets and more than six physcial cores per sockets, consider removing CPU
  0 on socket 0 from the affinity mask, this affinitizes the rest of the database engine away from
  the log writer. When the instance starts up the log writer is usually assinged to NUMA node 0, CPU 
  0.

5. The SQL Server scheduler is not hyper-threading aware and therefore makes no any distinction 
  between scheduling a task on a logical processor on a core that is already in use by a hyper-thread
  as opposed to a CPU core which has nothing running on it. A second hyper-thread running on a core
  may get up 25% of the total cores compute  capacity. To get cleaner looking graphs, consider
  either turning off hyper-threading at the Bios/EFI level or disabling all odd numbered logical
  processors in the CPU affinity mask.

6. Turn on trace flag 2330, this stops spins on the OPT_IDX_STATS spinlock, this serialises access to
  the internal memory structures associated with the missing index feature DMVs.

7. Turn on trace flag 8008, this stops the SQL OS scheduling from using scheduler hints and can
  result much more even CPU core utilisation.

8. To quantify the overhead of CPU cache coherency on  passing around the cache line associated with
  the LOGCACHE_ACCESS spinlock, consider altering the CPU affinity mask on a two socket server
  such that the workload runs on NUMA node 0 in one test and then NUMA node 1 in another.

##Disclaimer

This software is  used at the users own risk, it is purely intended to provide a means of putting 
the database engine under stress, as such it should not be used against production envronments. Any
commitment to fix any potential bugs and or make enhancements is at the sole discretion of its author
in terms of if and when such work is carried out.